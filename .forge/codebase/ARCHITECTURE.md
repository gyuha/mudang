---
last_mapped_commit: d3b888938c188b4a3c60d93897ccf31159291c7e
mapped: 2026-06-21
---

# 아키텍처

## 한눈에 보는 현재 상태

이 저장소는 Godot 4 게임의 **초기 스캐폴드**다. 코드로 실제 구현되어 있는 것은 **데이터 계층 하나뿐**이다. 런타임 게임플레이 시스템(적 시스템, 무녀, 동료, 스폰 디렉터 등)은 `docs/`에 **설계만 되어 있고 코드는 아직 없다**.

따라서 이 문서는 두 개의 세계를 명확히 구분한다.

- **코드에 존재함 (IMPLEMENTED):** `scripts/data/*.gd`의 `Resource` 정의, `data/**/*.tres` 인스턴스, `tools/seed_stage1.gd` 시드 스크립트.
- **문서에만 존재함 (DESIGNED-BUT-NOT-BUILT):** `EnemySystem`(SoA + MultiMesh), `SpatialHash`, `RunScene` 트리, `WaveDirector`, `Mudang`, `CompanionManager` 등 일체의 런타임 시스템. 출처는 `docs/06-기술아키텍처.md`, `docs/07-수직슬라이스-로드맵.md`.

`project.godot`는 거의 비어 있는 골격이다. autoload, 메인 씬, 입력 맵 어느 것도 등록되어 있지 않다. 즉 현 시점에 실행 가능한 게임플레이는 없다.

```
project.godot (빈 골격)
      │
      ▼
scripts/data/*.gd  ──정의──▶  data/**/*.tres  ◀──재생성──  tools/seed_stage1.gd
 (Resource 스키마)            (저작된 인스턴스)            (EditorScript 시드)
      │
      └─ (런타임 로더/시스템: 미구현 — docs/에만 설계)
```

---

## 구현된 아키텍처 패턴: 데이터 주도 Resource 계층

현재 코드 전체를 관통하는 단 하나의 패턴은 **Godot `Resource` 기반 데이터 주도 설계**다. 게임의 콘텐츠(스테이지, 적, 목표, 스폰 규칙, 보상)를 코드가 아니라 `.tres` 데이터 파일로 표현하고, 각 데이터 종류마다 `Resource`를 상속한 GDScript 클래스로 스키마를 정의한다.

이 선택의 근거는 `docs/05-데이터스키마-저작도구.md`에 명시되어 있다(인스펙터 편집 UI 무료, `@export_range` 타입 검증 무료, `.tres`가 텍스트라 git diff 가능, `load()`로 핫리로드). 코드는 그 설계를 그대로 따른다.

### 계층 구조

`StageDef`가 최상위 컨테이너이며, 다른 Resource들을 합성(composition)으로 품는다.

```
StageDef (최상위 = 스테이지 1개 = 런 1회)
├─ objectives:  Array[ObjectiveDef]
├─ spawn_pool:  Array[SpawnPoolEntry] ─┐
├─ timeline:    Array[TimelineEvent]  ─┤─▶ enemy: EnemyDef ─▶ drop: DropTable
└─ reward:      StageReward
```

구현된 Resource 클래스 7종 (`scripts/data/`):

| 클래스 | 파일 | 역할(구조적) |
|--------|------|------|
| `StageDef` | `scripts/data/stage_def.gd` | 최상위. objectives/spawn_pool/timeline/reward를 합성. `budget_per_sec(t)`·`validate()` 메서드 보유 |
| `EnemyDef` | `scripts/data/enemy_def.gd` | 적 1종의 스탯/거동 필드. `drop: DropTable` 보유 |
| `DropTable` | `scripts/data/drop_table.gd` | 드랍 확률/수량 필드만 (메서드 없음) |
| `ObjectiveDef` | `scripts/data/objective_def.gd` | `kind: StringName` + `params: Dictionary`로 타입별 파라미터 표현 |
| `SpawnPoolEntry` | `scripts/data/spawn_pool_entry.gd` | `enemy` + 가중치 + 활성 구간. `is_active(t)` 메서드 보유 |
| `TimelineEvent` | `scripts/data/timeline_event.gd` | `Kind` enum + `time`/`enemy`/`count`/`payload` |
| `StageReward` | `scripts/data/stage_reward.gd` | 메타 재화/첫 클리어 보너스 필드만 |

모든 클래스는 `class_name X extends Resource` 형태로 전역 클래스명을 등록하므로, `.tres`에서 `script_class`로 참조되고 다른 `.gd`에서 직접 타입으로 사용된다.

### 핵심 추상화 / 설계 기법

코드에 실제로 나타난 기법들:

- **합성을 통한 중첩 Resource:** `StageDef` → `Array[SpawnPoolEntry]` → `EnemyDef` → `DropTable`로 이어지는 트리. `.tres`에서는 자식이 `[sub_resource]`(인라인) 또는 `[ext_resource]`(외부 파일 참조)로 직렬화된다. 실제 `data/stages/stage_hwalinseo.tres`에서 `EnemyDef`는 외부 `.tres` 참조, `ObjectiveDef`/`SpawnPoolEntry`/`TimelineEvent`/`StageReward`는 인라인 sub_resource로 작성되어 있다.
- **`StringName` + `Dictionary`를 쓴 유연 타입 분기:** `ObjectiveDef.kind`(`survive_time`/`defend_target`/`purify_zone`/`kill_boss`)와 `EnemyDef.ai_kind`는 enum이 아니라 `StringName`이고, 타입별 파라미터는 `params: Dictionary`로 둔다(`TimelineEvent.payload`도 동일). 스키마 조기 경직을 피하려는 의도다(`docs/07` 리스크 레지스터에 명시).
- **데이터에 박힌 작은 계산 메서드:** 순수 데이터 외에 두 개의 계산 헬퍼가 Resource 안에 있다 — `StageDef.budget_per_sec(t) = budget_base + budget_growth_per_sec * t`, `SpawnPoolEntry.is_active(t)`. 둘 다 시간 `t`를 받아 런타임이 호출하도록 의도된 순수 함수지만, **호출자(런타임)는 아직 없다.**
- **자가 검증(self-validation):** `StageDef.validate() -> Array`가 duration/spawn/objective 빈 값 점검 후 에러 문자열 배열을 반환한다. `tools/seed_stage1.gd`가 이걸 호출해 결과를 출력한다.
- **예약 필드(미사용):** `StageDef.global_rule`, `StageDef.hazards`, `StageDef.unlock_companion` 등은 `@export`로 선언만 되어 있고 슬라이스 데이터에서는 비어 있다. 후속 확장용 자리만 잡아둔 상태다.

---

## 데이터 흐름

### 저작(authoring) 흐름 — 현재 동작하는 유일한 흐름

```
scripts/data/*.gd 스키마 정의
        │
        ├─(A) 손작성: data/**/*.tres 직접 편집  (현재 stage_hwalinseo + 적 4종 존재)
        │
        └─(B) 코드 시드: tools/seed_stage1.gd (EditorScript, @tool)
                 Godot 에디터에서 File > Run
                 → EnemyDef/StageDef를 코드로 빌드
                 → ResourceSaver.save()로 res://data/ 에 .tres 재생성
                 → StageDef.validate() 결과 print
```

`tools/seed_stage1.gd`는 손작성 `.tres`가 포맷 문제로 안 열릴 때 동일 데이터를 코드로 다시 만들어내는 백업/검증 경로다(`docs/05`§4 "1단계: 도구 없음" 정신). 손작성본과 시드 코드는 동일한 수치를 표현하도록 의도되어 있다(예: `mob_low` hp=6, `ghost_maiden` speed=130, stage duration=360).

### 런타임 흐름 — 미구현

`docs/05`§3은 `stage_loader.gd`가 `load("res://data/stages/%s.tres" % id)`로 `StageDef`를 로드하는 로더를 명시하지만, **그 로더 파일은 존재하지 않는다.** 데이터를 읽어 게임을 굴리는 코드 경로는 전무하다. 데이터 계층은 현재 "쓰여지기만 하고 읽혀지지 않는" 상태다.

---

## 진입점(entry points)

| 종류 | 위치 | 상태 |
|------|------|------|
| 게임 메인 씬 | `project.godot`에 `run/main_scene` 미설정 | **없음** |
| autoload (GameState/MetaProgress/InputAdapter) | `project.godot`에 `[autoload]` 섹션 자체가 없음 | **없음** |
| 데이터 시드 진입점 | `tools/seed_stage1.gd` `_run()` (에디터에서 수동 실행) | 존재 |
| 데이터 저작 단위 | `data/stages/stage_hwalinseo.tres` | 존재 |

현재 사람이 실행할 수 있는 코드 진입점은 `tools/seed_stage1.gd`의 에디터 `Run` 하나뿐이다. 게임으로서의 진입점(메인 씬, 첫 autoload)은 아직 없다.

---

## 설계되었으나 미구축인 런타임 아키텍처 (DESIGNED-BUT-NOT-BUILT)

아래는 **`docs/`에 설계만 있고 코드는 없는** 목표 아키텍처의 요지다. 구현 시 이 데이터 계층을 소비하게 될 대상이다. 전문은 출처 문서를 직접 참조할 것 — 여기서는 데이터 계층과의 접점만 짚는다.

출처: `docs/06-기술아키텍처.md`(시스템 설계), `docs/07-수직슬라이스-로드맵.md`(구현 순서/마일스톤), `docs/05-데이터스키마-저작도구.md`(로더/저작 도구).

- **`EnemySystem` (SoA + MultiMesh):** 적 ~500마리를 Node가 아니라 구조화 배열(`position[]`/`velocity[]`/`hp[]`/`def_idx[]` 등 Packed 배열)로 관리하고 `MultiMeshInstance2D` 한 드로우콜로 그린다는 설계(`docs/06`§1). `def_idx`가 가리킬 정의가 곧 구현된 `EnemyDef`다. 코드 없음.
- **`SpatialHash`:** 물리 엔진 없이 균일 격자로 근접 질의(오라/넉백/혼불 자석/타게팅). 매 프레임 재구축 방식(`docs/06`§2). 코드 없음.
- **`RunScene` 씬 트리:** `Main → RunScene(Camera2D, Background, Mudang, CompanionManager, EnemySystem, SoulfireSystem, WaveDirector, ObjectiveManager, SpatialHash, HUD ...)` (`docs/06`§3). 어느 노드/씬도 존재하지 않는다.
- **`WaveDirector`:** `StageDef`의 `spawn_pool`(예산 채널, `budget_per_sec(t)`)과 `timeline`(고정 이벤트)을 읽어 스폰을 구동하도록 설계(`docs/06`§4 업데이트 순서, `docs/05`). 구현된 `budget_per_sec`/`is_active`/`ObjectiveDef`/`TimelineEvent`가 바로 이 시스템의 입력이다. 코드 없음.
- **로더 `stage_loader.gd` / `MetaProgress` 세이브:** `docs/05`§3, `docs/06`§6에 설계. 코드 없음.

로드맵(`docs/07`)상 가장 먼저 세울 골격은 M0(RunScene·GameState·InputAdapter·Camera + 무녀 이동 + 성능 스파이크)이며, 이 작업은 `.forge/backlog/m0-project-skeleton.md`에 백로그로 잡혀 있으나 아직 미실행이다. 데이터를 실제로 소비하는 스폰/목표 시스템(`WaveDirector`)은 그보다 뒤인 M6에 배치되어 있다.

> 요약: **데이터 계층의 "그릇"은 완성되어 있고 내용물(슬라이스 1장)도 채워져 있으나, 그것을 먹을 "런타임"은 아직 존재하지 않는다.** 두 세계의 다리는 미구현 로더와 미구현 `WaveDirector`다.

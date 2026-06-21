---
last_mapped_commit: d3b888938c188b4a3c60d93897ccf31159291c7e
mapped: 2026-06-21
---

# 구조

## 디렉토리 레이아웃

저장소 루트는 Godot 4 프로젝트 루트(`project.godot` 위치)와 동일하다.

```
mudang/
├─ project.godot          # Godot 4 프로젝트 파일 (거의 빈 골격: name/description/renderer만)
├─ README.md              # 2줄 (제목 "Mudang: Caller of the Night"만)
├─ DESIGN.md              # (git 추적 전 — 상위 디자인 문서, 루트 배치)
│
├─ scripts/               # GDScript 소스
│  └─ data/               # ★ 구현된 코드 전부가 여기 (Resource 스키마 7종)
│     ├─ stage_def.gd
│     ├─ enemy_def.gd
│     ├─ drop_table.gd
│     ├─ objective_def.gd
│     ├─ spawn_pool_entry.gd
│     ├─ timeline_event.gd
│     └─ stage_reward.gd
│
├─ data/                  # ★ 저작된 .tres 인스턴스 (콘텐츠 데이터)
│  ├─ stages/
│  │  └─ stage_hwalinseo.tres     # 슬라이스 1장 "활인서의 밤"
│  └─ enemies/
│     ├─ mob_low.tres
│     ├─ ghost_maiden.tres
│     ├─ dokkaebi.tres
│     └─ boss_hwalinseo.tres
│
├─ tools/                 # 에디터 전용 유틸리티
│  └─ seed_stage1.gd      # @tool EditorScript — data/*.tres 재생성/검증
│
├─ docs/                  # ★ 설계 문서 (한국어). 코드 아님 — 권위 있는 출처
│  ├─ 00-개요-결정-용어.md
│  ├─ 01-코어루프-무녀.md
│  ├─ 02-동료AI-케어.md
│  ├─ 03-혼불경제-성장-메타.md
│  ├─ 04-적-스폰시스템.md
│  ├─ 05-데이터스키마-저작도구.md
│  ├─ 06-기술아키텍처.md
│  ├─ 07-수직슬라이스-로드맵.md
│  ├─ 08-아트-오디오-방향.md
│  ├─ 09-슬라이스-수치표.md
│  ├─ 10-대시보드-스테이지선택-6스테이지.md
│  └─ 11-구현-배관-보강.md
│
└─ .forge/                # forge 워크플로우 상태 (코드 아님)
   ├─ backlog/
   │  └─ m0-project-skeleton.md   # M0 작업 계획 (미실행)
   └─ codebase/                   # 이 매핑 문서들의 출력 위치
```

핵심 관찰: **실행 가능한 GDScript는 `scripts/data/`(데이터 스키마) + `tools/`(에디터 시드) 두 곳뿐**이다. `scripts/`에는 `data/` 외 하위 디렉토리가 없다 — 런타임 코드(시스템/노드/씬)는 아직 작성되지 않았다. `*.tscn` 씬 파일은 저장소 전체에 한 개도 없다.

---

## 주요 위치 (key locations)

| 무엇을 찾을 때 | 위치 |
|----------------|------|
| Resource 스키마 정의(필드, `@export`) | `scripts/data/<이름>.gd` |
| 저작된 게임 콘텐츠 데이터 | `data/<범주>/<id>.tres` |
| 데이터 재생성/검증 스크립트 | `tools/seed_stage1.gd` |
| 설계 권위(왜/무엇을) | `docs/NN-*.md` (코드보다 docs가 출처) |
| 슬라이스 1장 전체 정의 | `data/stages/stage_hwalinseo.tres` |
| 진행 중 작업 계획 | `.forge/backlog/m0-project-skeleton.md` |
| 프로젝트 설정 | `project.godot` |

`docs/05`§3이 명시한 데이터 디렉토리 규약은 `res://data/{stages,enemies,companions,upgrades,droptables}/`이지만, 현재 실제로 존재하는 하위 폴더는 `stages/`와 `enemies/` 둘뿐이다(`companions`/`upgrades`/`droptables`는 아직 없음 — `DropTable`은 적 `.tres` 안에 인라인 sub_resource로 들어 있다).

---

## 명명 규칙 (naming conventions)

코드와 데이터에서 실제로 관찰되는 규칙:

### 파일명
- GDScript 파일: `snake_case.gd` (예: `stage_def.gd`, `spawn_pool_entry.gd`). 파일명은 그 안의 `class_name`의 snake_case 형태와 일치한다.
- 데이터 파일: `snake_case.tres`, 파일명(확장자 제외)이 곧 Resource의 `id` 값과 일치한다 — `ghost_maiden.tres` 안의 `id = &"ghost_maiden"`. `docs/05`§3의 "id == 파일명" 규약을 따른다.

### 클래스 / 식별자
- 클래스명: `PascalCase` + `Def`/`Table`/`Entry`/`Event`/`Reward` 접미사로 역할 표시 (`StageDef`, `EnemyDef`, `DropTable`, `SpawnPoolEntry`, `TimelineEvent`, `StageReward`). 모든 데이터 클래스는 `class_name X extends Resource`로 전역 등록.
- `id` 필드 타입은 일관되게 `StringName`(`&"..."` 리터럴). 분기용 종류 필드도 `StringName`을 선호한다 — `ObjectiveDef.kind`(`&"survive_time"` 등), `EnemyDef.ai_kind`(`&"rush_companion"` 등). 단 `TimelineEvent.kind`만 예외적으로 `enum Kind { SPAWN_GROUP, MINIBOSS, RUSH, OBJECTIVE, MODIFIER }`를 쓴다.
- 유연 파라미터는 `params`/`payload` 라는 이름의 `Dictionary`로 통일.

### 주석 컨벤션
- 모든 `.gd`가 파일 상단에 `##` doc-comment로 역할을 적고, 괄호로 설계 출처를 인용한다: `([docs/04]§2.2, [docs/09]§5)`, `(DESIGN §16)`. 코드가 어느 설계 문서의 어느 절을 구현하는지 역추적할 수 있게 하는 일관된 관행.
- 후속 확장용 예약 필드는 `# --- 후속 확장 ... 슬라이스는 비워둠 ---` 식 구분 주석으로 표시.

### 문서
- `docs/`는 `NN-한국어제목.md`(2자리 번호 접두) 형식으로 정렬. 본문은 전부 한국어.
- 문서 상호 참조는 `[NN]` 또는 `[docs/NN]§절` 표기.

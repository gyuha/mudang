---
last_mapped_commit: d3b888938c188b4a3c60d93897ccf31159291c7e
mapped: 2026-06-21
---

# STACK

이 저장소는 Godot 4 게임 프로젝트의 초기 골격이다. 현재 단계에서는 실행 가능한 게임 씬이나 게임플레이 코드가 없고, 데이터 주도 설계의 토대가 되는 Resource 클래스 정의와 그 데이터(`.tres`)만 존재한다. 모든 주장은 아래에 명시한 실제 파일에서 직접 확인한 것이다.

## 엔진 / 런타임

- 엔진: **Godot 4** (`project.godot`의 `config/features=PackedStringArray("4.3", "Forward Plus")` — 즉 Godot 4.3 기준). [높음]
- 렌더링 백엔드: **Forward Plus** (`project.godot`의 `[rendering] renderer/rendering_method="forward_plus"`). [높음]
- 프로젝트 설정 파일: `project.godot` (`config_version=5`). 애플리케이션 이름/설명만 정의되어 있고 autoload, 입력 맵, 에디터 플러그인 항목은 없다. [높음]
- `docs/06-기술아키텍처.md`에도 "엔진 Godot 4 / GDScript, 2D 탑다운, PC 우선·모바일 이식"이라는 동일한 결정이 명시되어 있다(설계 문서이며 코드가 아님). [높음]

## 언어

- **GDScript** 단일 언어. 모든 코드 파일은 `.gd` 확장자다. [높음]
- C#/.NET(Mono) 흔적 없음: `.csproj`, `.sln`, `csharp_*` 설정이 전무하다. [높음]
- 네이티브 확장(GDExtension) 없음: `*.gdextension` 파일이 없다. [높음]

## 코드 구성

코드는 두 갈래로만 구성된다.

- 데이터 모델 — `scripts/data/*.gd`: 모두 `extends Resource` + `class_name`을 선언한 GDScript Resource 클래스다.
  - `scripts/data/stage_def.gd` — `StageDef` (스테이지 최상위 정의, `validate()`·`budget_per_sec()` 메서드 포함)
  - `scripts/data/enemy_def.gd` — `EnemyDef`
  - `scripts/data/drop_table.gd` — `DropTable`
  - `scripts/data/spawn_pool_entry.gd` — `SpawnPoolEntry` (`is_active()` 메서드 포함)
  - `scripts/data/timeline_event.gd` — `TimelineEvent` (`enum Kind` 포함)
  - `scripts/data/objective_def.gd` — `ObjectiveDef`
  - `scripts/data/stage_reward.gd` — `StageReward`
- 에디터 도구 — `tools/seed_stage1.gd`: `@tool` + `extends EditorScript`. Godot 에디터에서 `File > Run`으로 실행하는 시드/검증 스크립트로, 위 Resource 클래스들을 코드로 생성해 `res://data/`에 `.tres`로 저장하고 `validate()` 결과를 출력한다. 런타임 게임 코드가 아니라 에디터 전용이다. [높음]

씬 파일(`.tscn`), 오토로드 싱글톤, 입력 액션, 게임플레이 노드 스크립트는 아직 존재하지 않는다. [높음]

## 데이터 주도(Resource) 접근

게임 콘텐츠는 코드가 아니라 직렬화된 Godot Resource(`.tres`, `format=3`)로 표현된다. `.tres`는 `[ext_resource type="Script" ...]`로 위 GDScript 클래스를 가리키고, 인스펙터에 노출된 `@export` 필드 값을 담는다.

- `data/stages/stage_hwalinseo.tres` — `StageDef` 인스턴스. 하위 리소스(`ObjectiveDef`, `SpawnPoolEntry`, `TimelineEvent`, `StageReward`)를 `[sub_resource]`로 인라인하고, 적 정의는 `[ext_resource]`로 `data/enemies/*.tres`를 참조한다.
- `data/enemies/mob_low.tres`, `data/enemies/ghost_maiden.tres`, `data/enemies/dokkaebi.tres`, `data/enemies/boss_hwalinseo.tres` — 각각 `EnemyDef` 인스턴스이며 `DropTable`을 `[sub_resource]`로 인라인한다.

`@export` 필드는 GDScript 클래스에서, 그 값은 `.tres`에서 — 즉 스키마와 데이터가 분리되어 있다. 이 구조 덕분에 콘텐츠 추가/수정이 에디터의 인스펙터 편집 또는 `.tres` 텍스트 편집만으로 가능하다. [높음]

## 의존성

**외부 의존성 없음 — 엔진 표준 라이브러리만 사용한다.** [높음]

근거:

- `addons/` 디렉터리가 없다(에디터 플러그인/서드파티 애드온 부재).
- `*.gdextension` 파일이 없다(네이티브 플러그인 부재).
- 패키지 매니저 매니페스트(`package.json`, `requirements.txt`, `*.csproj` 등)가 없다.
- `project.godot`에 `[editor_plugins]` 또는 플러그인 활성화 항목이 없다.
- 코드는 Godot 내장 타입(`Resource`, `EditorScript`, `DirAccess`, `ResourceSaver`, `PackedScene`, `Curve`, `StringName` 등)만 참조한다.

## 빌드 / 실행 / 익스포트

- 별도 빌드 시스템 없음. Godot 에디터/엔진이 `project.godot`를 직접 로드한다. [높음]
- 익스포트 프리셋 없음: `export_presets.cfg`가 존재하지 않는다(아직 배포 빌드 구성이 없음). [높음]
- 현재 "실행" 경로는 게임 플레이가 아니라, `tools/seed_stage1.gd`를 에디터에서 Run 하여 데이터를 시드/검증하는 것이다. [높음]

## 설계 문서(구조적 사실로만 기재)

`docs/00`~`docs/11`의 한국어 Markdown 파일과 루트의 `DESIGN.md`, `README.md`가 존재한다. 이들은 **설계/기획 명세이며 코드가 아니다**. GDScript 파일과 `.tres`의 주석은 이 문서들의 섹션(예: `[docs/05]§2.1`)을 출처로 참조한다. 본 STACK 문서는 그 도메인/설계 내용을 옮기지 않으며, 존재 사실만 기록한다. [높음]

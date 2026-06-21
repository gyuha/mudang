---
last_mapped_commit: d3b888938c188b4a3c60d93897ccf31159291c7e
mapped: 2026-06-21
---

# 코드 컨벤션 (Godot 4 GDScript)

이 문서는 `scripts/data/*.gd`, `tools/seed_stage1.gd`, `data/**/*.tres`에서 **실제 관찰된** 규약만 기술한다. 추정이 아니라 코드에 존재하는 패턴이다. 현재 코드베이스는 데이터 정의 리소스(7개)와 시드 EditorScript(1개)로만 구성되어 있으므로, 아래 규약은 그 범위에서 도출된 것이다.

## 1. 리소스 클래스 정의 패턴

모든 데이터 정의 스크립트는 동일한 골격을 따른다: 파일 최상단 `##` 문서 주석 → `class_name` → `extends Resource`.

```
## 적 1종 정의. ([docs/04]§1, 수치는 [docs/09]§2)
class_name EnemyDef
extends Resource
```

(`scripts/data/enemy_def.gd:1-3`)

- `class_name`은 PascalCase이며 `Def` 접미사 또는 의미 명사를 쓴다: `StageDef`, `EnemyDef`, `ObjectiveDef`, `SpawnPoolEntry`, `StageReward`, `TimelineEvent`, `DropTable`.
- 전부 `extends Resource`. `.tres`로 직렬화되어 저작/로드되는 순수 데이터 객체이며, 노드(`Node`)나 씬 스크립트는 이 디렉터리에 없다.
- `class_name`을 선언하므로 `.tres` 헤더에서 `script_class="EnemyDef"`로 참조되고, 다른 스크립트에서 `EnemyDef.new()`로 직접 인스턴스화된다 (`tools/seed_stage1.gd:13`).

## 2. 파일·디렉터리 레이아웃

| 구분 | 위치 | 규칙 |
|------|------|------|
| 데이터 정의 스크립트 | `scripts/data/*.gd` | 파일명 snake_case, 클래스명 PascalCase의 snake_case 변환형 (`stage_def.gd` ↔ `StageDef`) |
| 데이터 인스턴스 | `data/<category>/*.tres` | 카테고리별 하위 폴더 (`data/enemies/`, `data/stages/`) |
| 에디터 도구 | `tools/*.gd` | `@tool` EditorScript |

`.tres` 파일명은 kebab/snake 형태이며 리소스의 `id` 필드와 일치한다. 예: `data/enemies/mob_low.tres`의 `id = &"mob_low"` (`data/enemies/mob_low.tres:15`), `data/stages/stage_hwalinseo.tres`의 `id = &"stage_hwalinseo"` (`data/stages/stage_hwalinseo.tres:84`). `enemy_def.gd:5`의 주석이 이를 명시한다: `## 식별자 (파일명과 일치 권장)`.

## 3. 식별자(id)는 StringName 리터럴

런타임 식별자 성격의 값은 `String`이 아니라 `StringName`을 쓰고, 리터럴은 `&"..."` 구문으로 작성한다.

- `@export var id: StringName = &""` (`scripts/data/enemy_def.gd:6`, `stage_def.gd:6`)
- `@export var ai_kind: StringName = &"rush_companion"` (`scripts/data/enemy_def.gd:13`)
- `@export var kind: StringName = &"survive_time"` (`scripts/data/objective_def.gd:7`)
- 컬렉션도 동일: `@export var recommended_roles: Array[StringName] = []` (`scripts/data/stage_def.gd:28`), `unlock_requires: Array[StringName]` (`stage_def.gd:26`)

`.tres`에도 그대로 `&"..."`로 직렬화된다: `ai_kind = &"rush_companion"` (`data/enemies/mob_low.tres:20`), `recommended_roles = [&"tank", &"healer"]` (`data/stages/stage_hwalinseo.tres:95`).

대조적으로, 표시용/자유 텍스트 문자열은 일반 `String`이다: `@export var display_name: String = ""` (`stage_def.gd:7`). id-성 값은 `StringName`, 사람이 읽는 텍스트는 `String`이라는 구분이 일관된다.

## 4. 필드 네이밍과 타입

- 모든 필드는 snake_case: `max_hp`, `move_speed`, `knockback_resist`, `contact_damage`, `spawn_cost`, `budget_growth_per_sec`, `mudang_soulfire_chance`.
- 모든 `@export` 변수에 명시적 타입 주석과 기본값을 둔다: `@export var max_hp: float = 10.0` (`enemy_def.gd:7`), `@export var spawn_cost: int = 1` (`enemy_def.gd:15`).
- `Array`는 항상 타입 파라미터를 붙인다: `Array[ObjectiveDef]`, `Array[SpawnPoolEntry]`, `Array[TimelineEvent]`, `Array[StringName]` (`stage_def.gd:12-13, 26, 28`). 예외는 `validate()`의 지역 변수 `var errs: Array = []`로 반환 컬렉션이라 비타입이다 (`stage_def.gd:42`).
- 자유 형식 데이터는 `Dictionary`: `@export var params: Dictionary = {}` (`objective_def.gd:13`), `@export var payload: Dictionary = {}` (`timeline_event.gd:14`).

## 5. @export 어노테이션 사용

| 어노테이션 | 용도 | 예 |
|------|------|-----|
| `@export` | 일반 직렬화 필드 | 전 파일 공통 |
| `@export_range(0.0, 1.0)` | 0~1 확률/비율 클램프 | `knockback_resist` (`enemy_def.gd:10`), `soulfire_ratio` (`stage_def.gd:23`), `mudang_soulfire_chance` / `companion_soulfire_chance` (`drop_table.gd:7, 11`) |
| `enum` + `@export var ... : Kind` | 고정 분류값 | `TimelineEvent`의 `enum Kind { SPAWN_GROUP, MINIBOSS, RUSH, OBJECTIVE, MODIFIER }`, `@export var kind: Kind = Kind.SPAWN_GROUP` (`timeline_event.gd:6, 9`) |

작업 지시에 언급된 `@export_enum`은 이 코드베이스에 **실제로는 쓰이지 않는다**. 분류값은 두 갈래로 나뉜다: 닫힌 집합이고 정수 직렬화가 무방하면 진짜 `enum`(`TimelineEvent.Kind`), 문자열 식별자로 다뤄야 하면 `StringName` + 주석으로 허용값을 나열한다(`EnemyDef.ai_kind`, `ObjectiveDef.kind`). 후자의 패턴이 다수다. `.tres`에서 enum은 정수로 직렬화된다: `kind = 0` / `kind = 1` / `kind = 2` (`data/stages/stage_hwalinseo.tres:45, 51, 58`).

리소스 참조 필드는 타입을 직접 명시한다: `@export var drop: DropTable` (`enemy_def.gd:21`), `@export var enemy: EnemyDef` (`spawn_pool_entry.gd:6`, `timeline_event.gd:11`), `@export var reward: StageReward` (`stage_def.gd:31`). 확장 예약 슬롯은 의도적으로 느슨한 `Resource` 타입으로 둔다: `@export var global_rule: Resource`, `@export var hazards: Array[Resource]` (`stage_def.gd:34-35`).

## 6. 주석 스타일

- **`##` 문서 주석**: 파일 최상단 클래스 설명과 필드 위 설명에 사용. 에디터 인스펙터에 노출되는 GDScript 공식 doc-comment다.
- **설계 문서 역참조**: doc 주석은 거의 항상 `[docs/NN]` 형식으로 출처 설계 문서를 인용한다. 절 번호까지 다는 경우가 많다.
  - `## 스테이지(=하나의 런/밤) 최상위 정의. 저작 도구의 편집 대상. ([docs/05]§2.1, [docs/10])` (`stage_def.gd:1`)
  - `## 예산 채널: budget_per_sec(t) = budget_base + budget_growth_per_sec * t  ([docs/04]§2.2, [docs/09]§5)` (`stage_def.gd:16`)
  - `## 적 1종 정의. ([docs/04]§1, 수치는 [docs/09]§2)` (`enemy_def.gd:1`)
- **허용값 열거**: `StringName`/`Dictionary` 필드처럼 타입이 강제하지 못하는 값 집합은 주석으로 나열한다.
  - `## AI 거동(...): rush_companion | target_companion | rush_lowhp | elite | ranged | boss` (`enemy_def.gd:12`)
  - `## survive_time | defend_target | purify_zone | kill_boss` (`objective_def.gd:6`)
  - `objective_def.gd:8-12`는 `params` Dictionary의 타입별 키 형태를 예시로 문서화한다.
- **`#` 일반 주석**: 섹션 구분 등 인스펙터에 노출할 필요 없는 코드 내 메모. `# --- 후속 확장(슬라이스 이후, D22 / [docs/10]§6). 슬라이스는 비워둠 ---` (`stage_def.gd:33`).
- 주석 언어는 **한국어**이며 식별자/허용값 토큰만 영문이다.

## 7. 메서드 패턴

데이터 리소스는 순수 데이터에 그치지 않고, 자기 데이터에 대한 계산/검증 메서드를 함께 둔다. 메서드는 snake_case이고 반환 타입을 명시한다.

- 파생 계산: `func budget_per_sec(t: float) -> float:` (`stage_def.gd:37-38`)
- 활성 판정: `func is_active(t: float) -> bool:` (`spawn_pool_entry.gd:14-15`)
- 데이터 검증: `func validate() -> Array:` — 오류 메시지 문자열을 배열로 모아 반환하며, 빈 배열이면 통과를 의미한다 (`stage_def.gd:41-49`).

## 8. EditorScript 도구 패턴

`tools/seed_stage1.gd`는 도구 스크립트의 관찰된 규약을 보여준다.

- `@tool` + `extends EditorScript`, 진입점은 `func _run() -> void:` (`seed_stage1.gd:6-7, 50`).
- 파일 상단 `##` 주석에 용도·실행 방법(`File > Run (Ctrl+Shift+X)`)·설계 의도를 기술한다 (`seed_stage1.gd:1-5`).
- 비공개 헬퍼는 `_` 접두사 + snake_case: `_build_enemy`, `_spawn`, `_event`, `_objective`, `_save` (`seed_stage1.gd:9, 30, 35, 40, 45`).
- 리소스를 코드로 빌드해 `ResourceSaver.save(res, path)`로 `res://data/...`에 저장하고, 결과를 `print()`로 보고한다 (`seed_stage1.gd:45-48`).
- 경로는 Godot `res://` 스킴 절대경로 문자열을 쓴다.
- 한 줄에 여러 대입을 세미콜론으로 묶는 축약을 헬퍼 빌더에서 허용한다: `s.enemy = enemy; s.weight = w; s.start_time = t0; s.end_time = t1` (`seed_stage1.gd:32`). 단, 정의 스크립트 본문에서는 이런 축약이 없다 — 도구 코드에 국한된 스타일이다.

## 9. 들여쓰기·포맷

- **탭 들여쓰기** (Godot GDScript 기본). 모든 `.gd` 파일 일관.
- 타입 주석 콜론 뒤 한 칸: `var id: StringName`. 대입 연산자 양옆 한 칸: `= &""`.
- 파일 끝에 개행 1개.

## 10. 오류 처리

전용 예외/에러 처리 인프라는 없다 (GDScript에는 예외가 없음). 관찰된 두 가지 방식:

1. **데이터 검증을 통한 사전 방어**: `StageDef.validate()`가 오류를 문자열 배열로 수집한다. 호출자가 빈 배열 여부로 판단한다. 던지지 않고 모은다 (`stage_def.gd:41-49`).
2. **도구의 반환 코드 확인**: `ResourceSaver.save`의 반환값을 `OK`와 비교해 성공/실패를 출력한다 — `print("save %s -> %s" % [path, "OK" if err == OK else "ERR %d" % err])` (`seed_stage1.gd:47-48`).

방어적 분기는 "불가능한 시나리오"가 아니라 실제 잘못된 저작 데이터(0 이하 duration, 스폰/목표 누락)에만 둔다 — `stage_def.gd:43-48`이 그 범위를 보여준다.

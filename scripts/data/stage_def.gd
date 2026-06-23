## 스테이지(=하나의 런/밤) 최상위 정의. 저작 도구의 편집 대상. ([docs/05]§2.1, [docs/10])
## 슬라이스(스테이지1)는 global_rule/hazards 없이 동작 — 후속 풀 차별화용 예약 필드.
class_name StageDef
extends Resource

@export var id: StringName = &""
@export var display_name: String = ""
## 기본 생존 목표 시간(초)
@export var duration: float = 360.0
@export var background: PackedScene

## 서사 카드(D23, [docs/11]§5): 장 시작 일러스트 경로 + 텍스트. 빈 텍스트면 카드 미표시.
@export var intro_image_path: String = ""
@export_multiline var intro_text: String = ""

@export var objectives: Array[ObjectiveDef] = []
@export var spawn_pool: Array[SpawnPoolEntry] = []
@export var timeline: Array[TimelineEvent] = []

## 예산 채널: budget_per_sec(t) = budget_base + budget_growth_per_sec * t  ([docs/04]§2.2, [docs/09]§5)
@export var budget_base: float = 2.0
@export var budget_growth_per_sec: float = 0.0333
## 동시 적 상한(플랫폼 열화 시 설정에서 하향, [docs/06])
@export var max_active_enemies: int = 500

## 무녀 혼불 비중 (나머지는 동료 혼불)
@export_range(0.0, 1.0) var soulfire_ratio: float = 0.6

## 해금 조건(선행 스테이지 id) — 선형 해금 판정 ([docs/10] D21)
@export var unlock_requires: Array[StringName] = []
## 브리핑 권장 편성 힌트(강제 아님): "tank","ranged","healer","aoe"
@export var recommended_roles: Array[StringName] = []
## 첫 클리어 시 해금 동료 id ("" = 없음)
@export var unlock_companion: StringName = &""
@export var reward: StageReward

# --- 후속 확장(슬라이스 이후, D22 / [docs/10]§6). 슬라이스는 비워둠 ---
@export var global_rule: Resource          # StageModifier (시야 반경/난이도 배율 등)
@export var hazards: Array[Resource] = []  # HazardDef (화재/독 확산, 봉인진 구역)

func budget_per_sec(t: float) -> float:
	return budget_base + budget_growth_per_sec * t

## 데이터 정합성 점검. 저작/실행 시 호출. ([docs/05]§5)
func validate() -> Array:
	var errs: Array = []
	if duration <= 0.0:
		errs.append("duration must be > 0")
	if spawn_pool.is_empty() and timeline.is_empty():
		errs.append("no spawns defined (spawn_pool/timeline both empty)")
	if objectives.is_empty():
		errs.append("no objectives")
	return errs

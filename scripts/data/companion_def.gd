## 동료 1종 정의 — 단일 리소스(role_id 분기, D25). ([docs/02]§2, 수치는 [docs/09]§1)
## EnemyDef와 동일 컨벤션: ## 주석, StringName id, snake_case, @export 명시 타입+기본값.
class_name CompanionDef
extends Resource

## 식별자 (파일명과 일치 권장)
@export var id: StringName = &""
@export var display_name: String = ""
## 역할(거동 분기): tank | ranged | healer | aoe ([docs/02]§2)
@export var role_id: StringName = &"tank"
@export var max_hp: float = 120.0
@export var move_speed: float = 200.0
## 공격력(0=지원 전용, 적 직접 공격 없음 — 견습무당)
@export var attack_damage: float = 8.0
## 공격 주기 s
@export var attack_period: float = 0.5
## 교전/사격 거리 px
@export var attack_range: float = 45.0
## >0 이면 도발(주변 적 어그로 유도) — 탱
@export var taunt_radius: float = 0.0
## 받는 피해 감소 0~1 — 탱
@export_range(0.0, 1.0) var damage_reduction: float = 0.0
## >0 이면 카이팅(이 거리 안에 적 들면 무녀 방향 후퇴 사격) — 원딜
@export var kite_min: float = 0.0
## >0 이면 힐(초당 회복량) — 견습무당
@export var heal_per_sec: float = 0.0
## 힐 반경 px
@export var heal_radius: float = 0.0
## 무녀에서 이 거리 넘으면 복귀 가중↑(고무줄, 모여라보다 약하게)
@export var leash_radius: float = 360.0
## 타겟 우선순위: 0=NEAREST 1=DENSEST 2=ELITE 3=LOWHP_ALLY ([docs/02]§2)
@export var target_priority: int = 0
## D9: 기본 false(자가후퇴 없음)
@export var self_preserve: bool = false

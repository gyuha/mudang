## 적 1종 정의. ([docs/04]§1, 수치는 [docs/09]§2)
class_name EnemyDef
extends Resource

## 식별자 (파일명과 일치 권장)
@export var id: StringName = &""
@export var max_hp: float = 10.0
@export var move_speed: float = 70.0
## 넉백 저항 0~1 (1=거의 안 밀림)
@export_range(0.0, 1.0) var knockback_resist: float = 0.2
@export var contact_damage: float = 4.0
## AI 거동(무녀 직접 추격 없음): rush_companion | target_companion | rush_lowhp | elite | ranged | boss
@export var ai_kind: StringName = &"rush_companion"
## 예산 스폰 비용 ([docs/04]§2.2)
@export var spawn_cost: int = 1
## 처치 시 부여 EXP(혼불 환산 외 별도 표기용)
@export var exp_value: int = 1
## 오라 레벨 보정용 ([docs/01]§2)
@export var level: int = 1
## 혼불 드랍
@export var drop: DropTable
## 표시 스프라이트 한 변 px(원본 텍스처 축소 기준). 잡몹 작게, 보스 크게. ([docs/08]§2)
@export var sprite_size: float = 28.0

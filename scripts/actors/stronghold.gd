## 병자 거점(M6, defend_target) — 보호 대상. ([docs/09]§3, [docs/04]§3, D14)
## 적이 타겟할 수 있고(EnemySystem.ally_targets에 포함), 접촉 시 HP 감소. HP 0 = 패배.
## 플레이스홀더 표현(HP바 연출은 M8 Non-goal).
class_name Stronghold
extends Node2D

const PLACEHOLDER_SIZE: float = 40.0

@export var max_hp: float = 300.0
var hp: float = 0.0

func _ready() -> void:
	hp = max_hp
	var rect := ColorRect.new()
	rect.color = Color(0.85, 0.78, 0.55)   # 거점(베이지) — 아군/적과 구분
	rect.size = Vector2(PLACEHOLDER_SIZE, PLACEHOLDER_SIZE)
	rect.position = -rect.size * 0.5
	add_child(rect)

## 접촉 피해(초당값 × dt). HP 0 미만 클램프.
func take_contact_damage(amount: float) -> void:
	hp = max(0.0, hp - amount)

func is_destroyed() -> bool:
	return hp <= 0.0

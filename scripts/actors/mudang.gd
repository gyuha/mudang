## 무녀 — 플레이어 액터(플레이스홀더 표현). ([docs/06]§3, 이동속도 [docs/01]§7/[docs/09]§0)
## 공격 없음. 이동만(오라/넉백/모여라는 후속 슬라이스). InputAdapter.move_vector를 읽어 이동.
class_name Mudang
extends Node2D

## 이동속도 px/s ([docs/01]§7, [docs/09]§0)
const MOVE_SPEED: float = 220.0
## 플레이스홀더 한 변 px (아트 에셋 없음)
const PLACEHOLDER_SIZE: float = 24.0
## 최대 HP ([docs/00] D6-a, [docs/09]§0). 무녀 사망=패배.
const MAX_HP: float = 100.0

## 현재 HP. 적 접촉 시 contact_damage/s로 감소.
var hp: float = MAX_HP

## 접촉 피해 적용(초당 값 × dt를 호출자가 전달). HP는 0 미만으로 안 내려간다.
func take_contact_damage(amount: float) -> void:
	hp = max(0.0, hp - amount)

func _ready() -> void:
	# 코드로 플레이스홀더 그리기(아트 에셋 없이). 중심 정렬된 ColorRect.
	var rect := ColorRect.new()
	rect.color = Color(0.9, 0.3, 0.5)
	rect.size = Vector2(PLACEHOLDER_SIZE, PLACEHOLDER_SIZE)
	rect.position = -rect.size * 0.5
	add_child(rect)

func _physics_process(delta: float) -> void:
	position += InputAdapter.move_vector * MOVE_SPEED * delta

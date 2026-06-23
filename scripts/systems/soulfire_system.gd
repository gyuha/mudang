## 혼불 시스템(M3) — 경량 풀(EnemySystem 축소판). ([docs/03]§1, [docs/01]§4, D10)
## 적 사망 시 드랍된 혼불 모트를 관리: 무녀 자석 픽업 → 무녀혼불=즉시흡수(EXP)/동료혼불=보유,
## 보유분은 transfer_range 내 최근접 1동료에 proximity-rate 자동 전달(+소폭 HP 회복).
## 노드가 아니라 병렬 배열 + 슬롯당 ColorRect 플레이스홀더(연출/자석 트레일은 M8 Non-goal).
class_name SoulfireSystem
extends Node2D

const KIND_MUDANG: int = 0
const KIND_COMPANION: int = 1
const PLACEHOLDER_SIZE: float = 8.0

var _pos: PackedVector2Array = PackedVector2Array()
var _kind: PackedInt32Array = PackedInt32Array()
var _amount: PackedFloat32Array = PackedFloat32Array()
var _rects: Array[ColorRect] = []
var _count: int = 0

## 혼불 수집 효율(M4 상실 디버프 — RunScene이 LOST 수로 주입). 흡수량에 곱. ([docs/02]§4)
var pickup_efficiency: float = 1.0

func active_count() -> int:
	return _count

## 혼불 모트 1개 스폰.
func spawn(kind: int, amount: float, pos: Vector2) -> void:
	var idx := _count
	if idx < _pos.size():
		_pos[idx] = pos
		_kind[idx] = kind
		_amount[idx] = amount
		_rects[idx].color = _kind_color(kind)
		_rects[idx].visible = true
		_rects[idx].position = pos - Vector2(PLACEHOLDER_SIZE, PLACEHOLDER_SIZE) * 0.5
	else:
		_pos.append(pos)
		_kind.append(kind)
		_amount.append(amount)
		var rect := ColorRect.new()
		rect.color = _kind_color(kind)
		rect.size = Vector2(PLACEHOLDER_SIZE, PLACEHOLDER_SIZE)
		rect.position = pos - rect.size * 0.5
		add_child(rect)
		_rects.append(rect)
	_count += 1

## 적 드랍테이블을 추첨해 혼불 스폰(EnemySystem.on_kill 훅에서 호출). ([docs/03]§1)
func spawn_from_drop(pos: Vector2, drop: DropTable) -> void:
	if randf() < drop.mudang_soulfire_chance and drop.mudang_soulfire_amount > 0:
		spawn(KIND_MUDANG, float(drop.mudang_soulfire_amount), pos)
	if randf() < drop.companion_soulfire_chance and drop.companion_soulfire_amount > 0:
		spawn(KIND_COMPANION, float(drop.companion_soulfire_amount), pos)

## 매 프레임: 무녀 자석 픽업 → 흡수/보유, 그리고 보유 동료혼불 → 최근접 1동료 자동 전달.
func update(dt: float, mudang: Node2D, companions: Array) -> void:
	# 1) 자석 픽업(pickup_radius 내 즉시 흡수). swap-remove라 역순 순회.
	var i := _count - 1
	while i >= 0:
		if _pos[i].distance_to(mudang.global_position) <= mudang.pickup_radius:
			# 상실 디버프: 수집 효율 배수 적용. ([docs/02]§4)
			var gained: float = _amount[i] * pickup_efficiency
			if _kind[i] == KIND_MUDANG:
				mudang.add_exp(gained)        # M5: EXP 적립 → 레벨업 감지
			else:
				mudang.companion_soulfire_held += gained
			_remove(i)
		i -= 1
	# 2) 보유 동료혼불 → 최근접 1동료 자동 전달(가까울수록 빠름). ([docs/01]§4)
	if mudang.companion_soulfire_held <= 0.0 or companions.is_empty():
		return
	var target: Companion = null
	var best_d := INF
	for c in companions:
		if c == null or c.def == null:
			continue
		var d := mudang.global_position.distance_to(c.global_position)
		if d < best_d:
			best_d = d
			target = c
	if target == null or best_d > mudang.transfer_range:
		return
	var proximity: float = clampf(1.0 - best_d / mudang.transfer_range, 0.0, 1.0)
	var rate: float = mudang.transfer_rate_max * proximity
	var amt: float = min(mudang.companion_soulfire_held, rate * dt)
	if amt <= 0.0:
		return
	mudang.companion_soulfire_held -= amt
	target.heal_received(amt * 0.5)        # 전달 시 소폭 회복(+0.5/량) — 견습무당 힐보다 약함
	target.add_companion_exp(amt)          # 동료 EXP 적립 → 레벨업 감지(M5)

func _kind_color(kind: int) -> Color:
	return Color(0.95, 0.92, 0.6) if kind == KIND_MUDANG else Color(0.3, 0.85, 0.85)

## swap-remove(빈 ColorRect 숨겨 재사용).
func _remove(idx: int) -> void:
	var last := _count - 1
	var dead_rect := _rects[idx]
	dead_rect.visible = false
	if idx != last:
		_pos[idx] = _pos[last]
		_kind[idx] = _kind[last]
		_amount[idx] = _amount[last]
		_rects[idx] = _rects[last]
		_rects[last] = dead_rect
	_count -= 1

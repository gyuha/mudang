## M4 케어 검증(S1~S4). 쓰러짐/부활/감쇠/상실+디버프를 격리 셋업으로 결정론적 판정.
## 머리 위 링·미니맵 등 연출은 제외(M8) — 타이머/상태/게이지 로직만.
extends Node2D

func _ready() -> void:
	var results := {}
	results["downed"] = _check_downed()
	results["lost"] = _check_lost()
	results["revive"] = _check_revive()
	results["decay"] = _check_decay()
	results["lost_debuff"] = _check_lost_debuff()

	var all := true
	for k in results:
		print("CARE %s => %s" % [k, "PASS" if results[k] else "FAIL"])
		all = all and results[k]
	print("CARE VERDICT => %s" % ["PASS" if all else "FAIL"])
	get_tree().quit()

func _tank() -> Companion:
	var c := Companion.new()
	c.def = load("res://data/companions/hwarang.tres") as CompanionDef
	add_child(c)   # _ready → hp=max(120)
	return c

# S1: 치명피해 → DOWNED(즉사 아님), 추가 피해 무효.
func _check_downed() -> bool:
	var c := _tank()
	c.take_contact_damage(200.0)   # >120 → 쓰러짐
	var downed := c.is_downed() and not c.is_lost()
	c.take_contact_damage(200.0)   # 무적 — 변화 없음
	print("  downed is_downed=%s hp=%.0f" % [c.is_downed(), c.hp])
	return downed and c.is_downed()

# S1: downed_timer 초과 → LOST.
func _check_lost() -> bool:
	var c := _tank()
	c.take_contact_damage(200.0)
	var dt := 0.1
	for _i in 90:   # 9s > 8s
		c.step(dt)
	print("  lost is_lost=%s" % c.is_lost())
	return c.is_lost()

# S2: 정지 근접 채널 revive_channel_time 누적 → 부활(40% HP, ACQUIRE 복귀).
func _check_revive() -> bool:
	var c := _tank()
	c.take_contact_damage(200.0)
	var revived := false
	for _i in 35:   # 3.5s > 3.0 channel_time
		if c.revive_progress(0.1, 3.0):
			revived = true
			break
	print("  revive revived=%s hp=%.0f downed=%s" % [revived, c.hp, c.is_downed()])
	# hwarang max 120 → 40% = 48
	return revived and not c.is_downed() and abs(c.hp - 48.0) < 1.0

# S2: 채널 도중 이탈(감쇠) → 부활 안 됨, 여전히 DOWNED.
func _check_decay() -> bool:
	var c := _tank()
	c.take_contact_damage(200.0)
	for _i in 10:   # 1.0s 충전(아직 3.0 미만)
		c.revive_progress(0.1, 3.0)
	for _i in 40:   # 이탈 감쇠
		c.revive_decay(0.1)
	# 감쇠 후 다시 충전해도 0부터 → 짧게는 부활 못 함
	var revived := c.revive_progress(0.1, 3.0)
	print("  decay revived=%s still_downed=%s" % [revived, c.is_downed()])
	return not revived and c.is_downed()

# S4: 상실 디버프 — pickup_efficiency 배수만큼 혼불 흡수량 감소.
func _check_lost_debuff() -> bool:
	var sf := SoulfireSystem.new(); add_child(sf)
	var mud := Mudang.new(); add_child(mud); mud.position = Vector2.ZERO
	sf.pickup_efficiency = 0.55   # LOST 3명 가정(1-0.15*3)
	sf.spawn(SoulfireSystem.KIND_MUDANG, 10.0, Vector2(30, 0))   # pickup 70 안
	sf.update(0.1, mud, [])
	print("  lost_debuff mudang_exp=%.2f (기대 5.5)" % mud.mudang_exp)
	return abs(mud.mudang_exp - 5.5) < 0.01

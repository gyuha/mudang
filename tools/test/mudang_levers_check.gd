## M3 무녀 레버 검증(S1~S6). 격리된 셋업을 수동 스텝으로 진행시켜
## 오라 감속·넉백(변위+resist+경직)·혼불 전달(흡수/보유/회복)·모여라 수렴을 결정론적으로 판정.
## 시전 입력/쿨다운 게이트는 RunScene 로직 → 여기선 시스템 단위 거동만(쿨다운은 RunScene 통합서 검증).
extends Node2D

func _ready() -> void:
	var results := {}
	results["aura"] = _check_aura()
	results["knockback"] = _check_knockback()
	results["soulfire"] = _check_soulfire()
	results["rally"] = _check_rally()

	var all := true
	for k in results:
		print("LEVER %s => %s" % [k, "PASS" if results[k] else "FAIL"])
		all = all and results[k]
	print("LEVER VERDICT => %s" % ["PASS" if all else "FAIL"])
	get_tree().quit()

func _fresh_enemies() -> EnemySystem:
	var e := EnemySystem.new()
	add_child(e)
	return e

func _mob() -> EnemyDef:
	return load("res://data/enemies/mob_low.tres") as EnemyDef

# 레버1 오라: 반경 내 적은 ×slow_multiplier로 느려지고, 반경 밖은 불변.
func _check_aura() -> bool:
	var e := _fresh_enemies()
	var target := Node2D.new(); add_child(target); target.position = Vector2(1000, 0)
	e.ally_targets = [target]
	e.aura_center = Vector2.ZERO
	e.aura_radius = 140.0
	e.aura_slow = 0.6
	var mob := _mob()   # move_speed 70
	var i_in := e.spawn(mob, Vector2(50, 0))    # 오라 안
	var i_out := e.spawn(mob, Vector2(300, 0))  # 오라 밖
	var in0 := e.position_of(i_in).x
	var out0 := e.position_of(i_out).x
	e.tick(0.1)
	var in_disp := e.position_of(i_in).x - in0
	var out_disp := e.position_of(i_out).x - out0
	# 안쪽=70*0.6*0.1=4.2, 바깥=70*0.1=7.0
	print("  aura in_disp=%.2f out_disp=%.2f (기대 4.2 / 7.0)" % [in_disp, out_disp])
	return in_disp < out_disp and abs(in_disp - out_disp * 0.6) < 0.5

# 레버2 넉백: 반경 내 적 바깥 변위, resist 높을수록 덜 밀림, 경직 중 이동 스킵.
func _check_knockback() -> bool:
	var e := _fresh_enemies()
	e.ally_targets = []   # tick은 해시만 구축(이동 없음)
	var low := EnemyDef.new(); low.max_hp = 999.0; low.move_speed = 70.0; low.knockback_resist = 0.1
	var high := EnemyDef.new(); high.max_hp = 999.0; high.move_speed = 70.0; high.knockback_resist = 0.9
	var i_low := e.spawn(low, Vector2(10, 0))
	var i_high := e.spawn(high, Vector2(0, 10))
	e.tick(0.05)   # 해시 구축
	e.apply_knockback(Vector2.ZERO, 90.0, 380.0)
	var low_d := e.position_of(i_low).distance_to(Vector2.ZERO)
	var high_d := e.position_of(i_high).distance_to(Vector2.ZERO)
	# low: 10+380*0.9=352, high: 10+380*0.1=48
	print("  knockback low_d=%.0f high_d=%.0f (기대 ~352 / ~48)" % [low_d, high_d])
	var pushed := low_d > 300.0 and high_d < 80.0 and low_d > high_d
	# 경직: 넉백 직후 타겟을 향해 tick해도 이동 안 함.
	var tgt := Node2D.new(); add_child(tgt); tgt.position = Vector2.ZERO
	e.ally_targets = [tgt]
	var before := e.position_of(i_low)
	e.tick(0.1)
	var stun_held := e.position_of(i_low).distance_to(before) < 0.01
	print("  knockback stun_held=%s" % stun_held)
	return pushed and stun_held

# 레버3 혼불: 자석 흡수(무녀혼불→EXP, 동료혼불→보유) + 보유분 근접 동료 전달(+회복, EXP).
func _check_soulfire() -> bool:
	var sf := SoulfireSystem.new(); add_child(sf)
	var mud := Mudang.new(); add_child(mud); mud.position = Vector2.ZERO
	var comp := Companion.new(); comp.def = load("res://data/companions/hwarang.tres") as CompanionDef
	add_child(comp); comp.position = Vector2(60, 0); comp.hp = 10.0   # transfer_range 110 안, 부상
	sf.spawn(SoulfireSystem.KIND_MUDANG, 1.0, Vector2(30, 0))      # pickup_radius 70 안
	sf.spawn(SoulfireSystem.KIND_COMPANION, 5.0, Vector2(40, 0))   # pickup_radius 70 안
	var hp0 := comp.hp
	for _i in 30:
		sf.update(0.1, mud, [comp])
	print("  soulfire exp=%.1f held=%.2f comp_hp %.1f->%.1f comp_exp=%.2f" % [
		mud.mudang_exp, mud.companion_soulfire_held, hp0, comp.hp, comp.companion_exp])
	return mud.mudang_exp >= 1.0 and comp.hp > hp0 and comp.companion_exp > 0.0 and mud.companion_soulfire_held < 5.0

# 레버4 모여라: 원거리 적 추격을 이기고 무녀로 수렴.
func _check_rally() -> bool:
	var e := _fresh_enemies()
	var mud := Mudang.new(); add_child(mud); mud.position = Vector2.ZERO
	var comp := Companion.new(); comp.def = load("res://data/companions/hwaljabi.tres") as CompanionDef
	add_child(comp); comp.position = Vector2(200, 0)
	comp.enemies = e
	comp.mudang = mud
	comp.allies = [comp]
	e.ally_targets = [comp]
	e.spawn(_mob(), Vector2(400, 0))   # 무녀 반대편(없으면 추격해 멀어짐)
	var before := comp.position.distance_to(mud.position)
	comp.start_rally(4.0)
	var dt := 0.05
	for _i in 30:
		e.tick(dt)
		comp.step(dt)
	var after := comp.position.distance_to(mud.position)
	print("  rally dist %.0f -> %.0f" % [before, after])
	return after < before

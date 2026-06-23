## M5 성장 로직 검증(S1~S3). EXP 곡선·무녀 레벨업+업그레이드 적용·동료 레벨업+pending을 판정.
## 3택 UI/일시정지/비정지 보류카드 UX는 M5-UI(human wall) — 여기선 곡선/적립/적용 로직만.
extends Node2D

func _ready() -> void:
	var results := {}
	results["mudang_curve"] = _check_mudang_curve()
	results["mudang_levelup"] = _check_mudang_levelup()
	results["apply_upgrade"] = _check_apply_upgrade()
	results["companion_levelup"] = _check_companion_levelup()

	var all := true
	for k in results:
		print("GROWTH %s => %s" % [k, "PASS" if results[k] else "FAIL"])
		all = all and results[k]
	print("GROWTH VERDICT => %s" % ["PASS" if all else "FAIL"])
	get_tree().quit()

func _mudang() -> Mudang:
	var m := Mudang.new()
	add_child(m)
	return m

# S2: EXP 곡선이 공식 floor(8*1.15^(n-1))과 일치.
func _check_mudang_curve() -> bool:
	var m := _mudang()
	var ok := m.exp_to_next(1) == 8 and m.exp_to_next(2) == 9 and m.exp_to_next(5) == 13
	print("  curve n1=%d n2=%d n5=%d (기대 8/9/13)" % [m.exp_to_next(1), m.exp_to_next(2), m.exp_to_next(5)])
	return ok

# S2: EXP 누적 → 레벨업 + pending(초과분 이월).
func _check_mudang_levelup() -> bool:
	var m := _mudang()
	m.add_exp(8.0)    # exp_to_next(1)=8 → Lv2, pending 1, exp 0
	var step1 := m.mudang_level == 2 and m.pending_picks() == 1
	m.add_exp(20.0)   # 9(Lv2)+10(Lv3)=19 소비 → Lv4, exp 1, pending 3
	print("  levelup Lv=%d exp=%.0f pending=%d (기대 Lv4/exp1/pend3)" % [
		m.mudang_level, m.mudang_exp, m.pending_picks()])
	return step1 and m.mudang_level == 4 and m.pending_picks() == 3

# S2: 업그레이드 적용 시 레버 파라미터가 델타만큼 증가(데이터 주도).
func _check_apply_upgrade() -> bool:
	var m := _mudang()
	m._pending_picks = 2
	var aura0 := m.aura_radius
	var force0 := m.knockback_force
	var rad0 := m.knockback_radius
	m.apply_upgrade(load("res://data/upgrades/mudang/aura_expand.tres") as MudangUpgrade)
	m.apply_upgrade(load("res://data/upgrades/mudang/knockback_power.tres") as MudangUpgrade)
	print("  apply aura %.0f->%.0f force %.0f->%.0f rad %.0f->%.0f pend=%d" % [
		aura0, m.aura_radius, force0, m.knockback_force, rad0, m.knockback_radius, m.pending_picks()])
	return is_equal_approx(m.aura_radius, aura0 + 20.0) \
		and is_equal_approx(m.knockback_force, force0 + 60.0) \
		and is_equal_approx(m.knockback_radius, rad0 + 12.0) \
		and m.pending_picks() == 0

# S2b: 동료 EXP → 레벨업 → pending_upgrades(상한 3).
func _check_companion_levelup() -> bool:
	var c := Companion.new()
	c.def = load("res://data/companions/hwarang.tres") as CompanionDef
	add_child(c)
	var n1 := c.comp_exp_to_next(1)   # floor(6*1.18^0)=6
	c.add_companion_exp(float(n1))     # Lv2, pending 1
	var step1 := c.companion_level == 2 and c.pending_upgrades == 1
	c.add_companion_exp(10000.0)       # 다수 레벨업 → pending 상한 3
	print("  comp n1=%d Lv=%d pending=%d (기대 6/높음/3)" % [n1, c.companion_level, c.pending_upgrades])
	return n1 == 6 and step1 and c.pending_upgrades == 3

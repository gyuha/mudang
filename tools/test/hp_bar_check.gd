## HP 바 검증(S1~S3). HpBar 수학/색 + 무녀·동료 hp 바인딩 + 전투불능 회색을 판정.
## 실제 시각적 모양/위치는 GUI(main.tscn) — 헤드리스 불가. 여기선 비율→폭/색/바인딩 로직만.
extends Node2D

func _ready() -> void:
	var results := {}
	results["bar_math"] = _check_bar_math()
	results["bar_color"] = _check_bar_color()
	results["mudang_bind"] = _check_mudang_bind()
	results["companion_bind"] = _check_companion_bind()

	var all := true
	for k in results:
		print("HPBAR %s => %s" % [k, "PASS" if results[k] else "FAIL"])
		all = all and results[k]
	print("HPBAR VERDICT => %s" % ["PASS" if all else "FAIL"])
	get_tree().quit()

# S1: 비율→fill 폭 + 클램프.
func _check_bar_math() -> bool:
	var b := HpBar.new(); add_child(b)
	b.set_ratio(0.5)
	var half := is_equal_approx(b.fill_width(), HpBar.BAR_W * 0.5)
	b.set_ratio(1.5)   # 상한 클램프
	var hi := is_equal_approx(b.ratio, 1.0)
	b.set_ratio(-0.3)  # 하한 클램프
	var lo := is_equal_approx(b.ratio, 0.0) and is_equal_approx(b.fill_width(), 0.0)
	print("  bar_math half=%s clampHi=%s clampLo=%s" % [half, hi, lo])
	return half and hi and lo

# S1: 색 — 만피=녹, 빈사=적, 전투불능=회색.
func _check_bar_color() -> bool:
	var b := HpBar.new(); add_child(b)
	b.set_ratio(1.0)
	var full := b.fill_color()
	b.set_ratio(0.0)
	var empty := b.fill_color()
	var green_ok := full.g > full.r       # 만피: 녹 > 적
	var red_ok := empty.r > empty.g        # 빈사: 적 > 녹
	b.set_ratio(1.0); b.set_incapacitated(true)
	var g := b.fill_color()
	var grey_ok := is_equal_approx(g.r, g.g) and is_equal_approx(g.g, g.b)   # 회색=R=G=B
	print("  bar_color green=%s red=%s grey=%s" % [green_ok, red_ok, grey_ok])
	return green_ok and red_ok and grey_ok

# S2: 무녀 hp/MAX_HP → 바 비율.
func _check_mudang_bind() -> bool:
	var m := Mudang.new(); add_child(m)
	m.hp = 50.0   # MAX_HP 100
	m.refresh_hp_bar()
	print("  mudang_bind hp=50 ratio=%.2f (기대 0.5)" % m.hp_bar.ratio)
	return is_equal_approx(m.hp_bar.ratio, 0.5)

# S2b: 동료 hp/def.max_hp → 바 비율, 쓰러짐 → 회색.
func _check_companion_bind() -> bool:
	var c := Companion.new()
	c.def = load("res://data/companions/hwarang.tres") as CompanionDef   # max 120
	add_child(c)
	c.hp = 30.0
	c.refresh_hp_bar()
	var bound := is_equal_approx(c.hp_bar.ratio, 30.0 / 120.0)
	c.take_contact_damage(500.0)   # 치명 → 쓰러짐(DOWNED)
	c.refresh_hp_bar()
	var grey := c.hp_bar.incapacitated
	print("  companion_bind ratio=%.3f downed_grey=%s" % [30.0 / 120.0, grey])
	return bound and grey

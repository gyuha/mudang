## M5-UI 3택 검증. 후보 생성(미만렙 ≤3, 만렙 제외) + 선택 적용(파라미터 강화·레벨·pending 소비).
## 일시정지/렌더/클릭 체감은 GUI(사용자) — 여기선 후보/적용 로직만.
extends Node2D

func _ready() -> void:
	var results := {}
	results["candidates"] = _check_candidates()
	results["apply"] = _check_apply()

	var all := true
	for k in results:
		print("LVLUI %s => %s" % [k, "PASS" if results[k] else "FAIL"])
		all = all and results[k]
	print("LVLUI VERDICT => %s" % ["PASS" if all else "FAIL"])
	get_tree().quit()

func _pool() -> Array:
	var out: Array = []
	for p in ["aura_expand", "aura_deepen", "knockback_power", "transfer_speed"]:
		out.append(load("res://data/upgrades/mudang/%s.tres" % p) as MudangUpgrade)
	return out

# 후보: 미만렙 최대 3개, 전부 만렙이면 0.
func _check_candidates() -> bool:
	var ui := LevelUpChoice.new(); add_child(ui)
	var pool := _pool()
	var levels := {}
	ui.setup(pool, levels, null)
	var three := ui.pick_candidates().size() == 3   # 풀 4 → 3택
	# 전부 만렙 → 0
	for up in pool:
		levels[up.id] = up.max_level
	var none := ui.pick_candidates().size() == 0
	print("  candidates three=%s none_when_maxed=%s" % [three, none])
	return three and none

# 선택 적용: 레버 파라미터 +델타, 레벨++, pending 소비.
func _check_apply() -> bool:
	var ui := LevelUpChoice.new(); add_child(ui)
	var pool := _pool()
	var levels := {}
	var m := Mudang.new(); add_child(m)
	m._pending_picks = 2
	ui.setup(pool, levels, m)
	var aura0 := m.aura_radius
	var aura_card: MudangUpgrade = null
	for up in pool:
		if up.id == &"aura_expand":
			aura_card = up
	ui._on_pick(aura_card)
	print("  apply aura %.0f->%.0f lvl=%d pending=%d (기대 +20/1/1)" % [
		aura0, m.aura_radius, int(levels.get(&"aura_expand", 0)), m.pending_picks()])
	return is_equal_approx(m.aura_radius, aura0 + 20.0) \
		and int(levels["aura_expand"]) == 1 and m.pending_picks() == 1

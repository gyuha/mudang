## 편성+결과 검증(task 22). Loadout 슬롯/선택/RUN 전이 · RunScene 편성 소비 · Result 표시/대시보드 복귀.
extends Node2D

func _ready() -> void:
	await _run()

func _run() -> void:
	var ok := true

	# --- A. Loadout: 풀 3종, 슬롯 2 상한, 확정 → RUN ---
	GameState.set_state(GameState.S.LOADOUT)
	GameState.selected_companions = []
	var lo := Loadout.new()
	lo.meta = MetaProgress.new()  # loadout_slots 기본 2
	add_child(lo)
	var avail := lo.available_companions()
	var avail_ok: bool = avail.size() == 3
	var h := "res://data/companions/hwarang.tres"
	var a := "res://data/companions/hwaljabi.tres"
	var g := "res://data/companions/gyeonseup.tres"
	lo.toggle_companion(h)
	lo.toggle_companion(a)
	var two_ok: bool = lo.selected.size() == 2
	var slot_cap: bool = lo.toggle_companion(g) == false and lo.selected.size() == 2  # 슬롯 가득
	var confirmed: bool = lo.confirm()
	var route_run: bool = confirmed and GameState.state == GameState.S.RUN and GameState.selected_companions.size() == 2
	print("  loadout: avail=%d two=%s slot_cap=%s confirm=%s state_run=%s" % [avail.size(), two_ok, slot_cap, confirmed, route_run])
	ok = ok and avail_ok and two_ok and slot_cap and route_run

	# --- B. RunScene가 편성(2종)을 소비해 동료 2인 스폰 ---
	GameState.selected_stage_path = "res://data/stages/stage_hwalinseo.tres"
	var rs := RunScene.new()
	add_child(rs)
	await get_tree().physics_frame
	rs.set_physics_process(false)
	var comp_ok: bool = rs._companions.size() == 2
	print("  runscene consumes loadout: companions=%d expect=2 -> %s" % [rs._companions.size(), comp_ok])
	ok = ok and comp_ok
	rs.queue_free()

	# --- C. Result: 승리 표시 + 대시보드 복귀 ---
	GameState.last_result = &"win"
	var r := Result.new()
	add_child(r)
	var win_text: bool = "승리" in r.result_text()
	GameState.set_state(GameState.S.RESULT)
	r.to_dashboard()
	var back_dash: bool = GameState.state == GameState.S.DASHBOARD
	print("  result: win_text=%s to_dashboard_state=%d(DASHBOARD=%d)" % [win_text, GameState.state, GameState.S.DASHBOARD])
	ok = ok and win_text and back_dash

	print("LOADOUT_RESULT VERDICT => %s" % ["PASS" if ok else "FAIL"])
	get_tree().quit()

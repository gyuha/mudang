## 메타 루프 흐름 검증(C3, task 23). Main 라우팅으로 대시보드→선택→편성→런→승리→해금저장→대시보드 복귀.
## 승리는 실제 라우팅을 태우기 위해 stage1 duration을 짧게 강제(생존승리 트리거) — 승패 조건 자체는 stage*_check가 검증.
extends Node2D

func _ready() -> void:
	await _run()

func _run() -> void:
	var ok := true
	# 깨끗한 메타에서 시작(이전 실행 세이브 제거).
	var abs_save := ProjectSettings.globalize_path("user://save.json")
	if FileAccess.file_exists("user://save.json"):
		DirAccess.remove_absolute(abs_save)

	# --- 진입: Main → DASHBOARD ---
	var main := Main.new()
	add_child(main)
	await get_tree().process_frame
	var at_dash: bool = GameState.state == GameState.S.DASHBOARD and main._screen is Dashboard
	print("  boot→dashboard: state=%d screen=%s -> %s" % [GameState.state, main._screen.get_class(), at_dash])
	ok = ok and at_dash

	# --- 스테이지 선택(1장) → LOADOUT ---
	var dash: Dashboard = main._screen
	var s1_path: String = dash.stage_entries()[0].path
	dash.select_stage(s1_path)
	await get_tree().process_frame
	var at_loadout: bool = GameState.state == GameState.S.LOADOUT and main._screen is Loadout and GameState.selected_stage_path == s1_path
	print("  select→loadout: state=%d screen=%s -> %s" % [GameState.state, main._screen.get_class(), at_loadout])
	ok = ok and at_loadout

	# --- 편성 확정(1명) → RUN ---
	var lo: Loadout = main._screen
	lo.toggle_companion("res://data/companions/hwarang.tres")
	lo.confirm()
	await get_tree().process_frame
	var at_run: bool = GameState.state == GameState.S.RUN and main._screen is RunScene
	print("  confirm→run: state=%d screen=%s -> %s" % [GameState.state, main._screen.get_class(), at_run])
	ok = ok and at_run

	# --- 런 강제 승리(stage1 생존: duration을 짧게) → RESULT ---
	# 트리 자동 구동을 끄고 수동으로 1틱 굴려 결정적으로 승리 트리거(stage456_check와 동일 패턴).
	var rs: RunScene = main._screen
	rs.set_physics_process(false)
	rs._stage.duration = 0.001
	rs._physics_process(0.1)  # _run_time=0.1 >= duration → 생존 승리 → set_state(RESULT) → Main이 Result로 교체
	await get_tree().process_frame
	var at_result: bool = GameState.state == GameState.S.RESULT and main._screen is Result and GameState.last_result == &"win"
	print("  run→result(win): state=%d screen=%s last=%s -> %s" % [GameState.state, main._screen.get_class(), GameState.last_result, at_result])
	ok = ok and at_result

	# --- 해금/저장 확인: 세이브 파일에 stage1 클리어 기록 ---
	var saved := MetaProgress.load_or_new()
	var rec: Dictionary = saved.stage_records.get("stage_hwalinseo", {})
	var meta_saved: bool = FileAccess.file_exists("user://save.json") and bool(rec.get("cleared", false)) and ("stage_hwalinseo" in saved.unlocked_stages)
	print("  meta saved: cleared=%s unlocked=%s -> %s" % [rec.get("cleared", false), "stage_hwalinseo" in saved.unlocked_stages, meta_saved])
	ok = ok and meta_saved

	# --- 결과 → 대시보드 복귀 ---
	var res: Result = main._screen
	res.to_dashboard()
	await get_tree().process_frame
	var back_dash: bool = GameState.state == GameState.S.DASHBOARD and main._screen is Dashboard
	print("  result→dashboard: state=%d screen=%s -> %s" % [GameState.state, main._screen.get_class(), back_dash])
	ok = ok and back_dash

	print("META_LOOP VERDICT => %s" % ["PASS" if ok else "FAIL"])
	get_tree().quit()

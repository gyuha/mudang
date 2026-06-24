## 스테이지 3 검증(데이터 축). stage3 로드/validate/kill_boss 목표 + RunScene 보스처치=WIN / 생존중=NONE.
extends Node2D
func _ready() -> void:
	# 1) 순수 평가 단위: kill_boss 분기.
	var none_alive := ObjectiveEval.evaluate(10.0, 300.0, 100.0, 1.0, true, false) == ObjectiveEval.NONE
	var win_dead := ObjectiveEval.evaluate(10.0, 300.0, 100.0, 1.0, true, true) == ObjectiveEval.WIN
	var lose_mudang := ObjectiveEval.evaluate(10.0, 300.0, 0.0, 1.0, true, false) == ObjectiveEval.LOSE
	print("  eval none_alive=%s win_dead=%s lose_mudang=%s" % [none_alive, win_dead, lose_mudang])

	# 2) 스테이지 데이터.
	var st := load("res://data/stages/stage_mountain_pass.tres") as StageDef
	var errs: Array = st.validate()
	var kb_id := ""
	var has_purify := false
	for o in st.objectives:
		if o.kind == &"kill_boss": kb_id = String(o.params.get("enemy_id", ""))
		if o.kind == &"purify_zone": has_purify = true
	var data_ok := errs.is_empty() and kb_id == "boss_tiger" and has_purify and st.duration == 300.0
	print("  data validate=%s kill_boss=%s purify_stub=%s" % [errs.is_empty(), kb_id, has_purify])

	# 3) RunScene을 stage3로 구동.
	GameState.selected_stage_path = "res://data/stages/stage_mountain_pass.tres"
	var rs := RunScene.new(); add_child(rs)
	await get_tree().physics_frame
	rs.set_physics_process(false)
	var tracked: bool = rs._kill_boss_targets.has(&"boss_tiger") and rs._kill_boss_targets[&"boss_tiger"] == false
	print("  run tracks boss=%s" % tracked)

	# 보스 미스폰/미처치 — NONE 유지 + 일반 적 스폰.
	for _i in 20:
		rs._physics_process(0.1)
	var none_ok := rs._result == ObjectiveEval.NONE
	var spawned := rs._enemies.active_count() > 0

	# 보스 직접 스폰 후 처치 → on_killed 훅이 추적 갱신 → WIN.
	var boss := load("res://data/enemies/boss_tiger.tres") as EnemyDef
	var bidx := rs._enemies.spawn(boss, Vector2(200, 0))
	rs._enemies.apply_damage(bidx, 99999.0)
	rs._physics_process(0.1)
	var win_ok := rs._result == ObjectiveEval.WIN
	print("  none_before=%s spawned=%s win_on_boss_kill=%s" % [none_ok, spawned, win_ok])

	var pass_all: bool = none_alive and win_dead and lose_mudang and data_ok and tracked and none_ok and spawned and win_ok
	print("STAGE3 VERDICT => %s" % ["PASS" if pass_all else "FAIL"])
	get_tree().quit()

## 스테이지 4·5·6 검증(계층① 데이터). validate/로드/승리경로 + StageDef 2~6 카운트.
extends Node2D
func _ready() -> void:
	# --- 4장: survive + purify(예약) + 독장판 2 ---
	var s4 := load("res://data/stages/stage_yangban_gut.tres") as StageDef
	var s4_purify := 0
	var s4_survive := false
	for o in s4.objectives:
		if o.kind == &"purify_zone": s4_purify += 1
		if o.kind == &"survive_time": s4_survive = true
	var s4_ok: bool = s4.validate().is_empty() and s4_survive and s4_purify >= 1 and s4.hazards.size() == 2
	print("  s4 validate=%s survive=%s purify=%d hazards=%d" % [s4.validate().is_empty(), s4_survive, s4_purify, s4.hazards.size()])

	# --- 5장: survive + 순차 purify 3(예약) ---
	var s5 := load("res://data/stages/stage_seonsucheong.tres") as StageDef
	var s5_purify := 0
	for o in s5.objectives:
		if o.kind == &"purify_zone": s5_purify += 1
	var s5_ok: bool = s5.validate().is_empty() and s5_purify == 3
	print("  s5 validate=%s purify_seq=%d" % [s5.validate().is_empty(), s5_purify])

	# --- 6장: kill_boss(boss_royal_wraith) + survive ---
	var s6 := load("res://data/stages/stage_palace_wraith.tres") as StageDef
	var s6_kb := ""
	for o in s6.objectives:
		if o.kind == &"kill_boss": s6_kb = String(o.params.get("enemy_id", ""))
	var s6_ok: bool = s6.validate().is_empty() and s6_kb == "boss_royal_wraith"
	print("  s6 validate=%s kill_boss=%s" % [s6.validate().is_empty(), s6_kb])

	# --- 6장 승리경로: RunScene 보스 처치 → WIN ---
	GameState.selected_stage_path = "res://data/stages/stage_palace_wraith.tres"
	var rs := RunScene.new(); add_child(rs)
	await get_tree().physics_frame
	rs.set_physics_process(false)
	var s6_tracks: bool = rs._kill_boss_targets.has(&"boss_royal_wraith")
	for _i in 15:
		rs._physics_process(0.1)
	var s6_none: bool = rs._result == ObjectiveEval.NONE
	var boss := load("res://data/enemies/boss_royal_wraith.tres") as EnemyDef
	var bidx := rs._enemies.spawn(boss, Vector2(150, 0))
	rs._enemies.apply_damage(bidx, 99999.0)
	rs._physics_process(0.1)
	var s6_win: bool = rs._result == ObjectiveEval.WIN
	print("  s6 run tracks=%s none_before=%s win_on_kill=%s" % [s6_tracks, s6_none, s6_win])

	# --- StageDef 2~6 모두 존재(+1장 = 6개) ---
	var stages := ["stage_hwalinseo", "stage_musnyeo_village", "stage_mountain_pass", "stage_yangban_gut", "stage_seonsucheong", "stage_palace_wraith"]
	var count := 0
	for sid in stages:
		if ResourceLoader.exists("res://data/stages/%s.tres" % sid): count += 1
	var count_ok: bool = count == 6
	print("  StageDef 1~6 present=%d/6" % count)

	var pass_all: bool = s4_ok and s5_ok and s6_ok and s6_tracks and s6_none and s6_win and count_ok
	print("STAGE456 VERDICT => %s" % ["PASS" if pass_all else "FAIL"])
	get_tree().quit()

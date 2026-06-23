## 스테이지 2 검증(데이터 축). stage2 로드/validate/목표·해저드 + RunScene 다중거점/해저드/다중거점패배.
extends Node2D
func _ready() -> void:
	var st := load("res://data/stages/stage_musnyeo_village.tres") as StageDef
	var errs: Array = st.validate()
	var defend := 0
	for o in st.objectives:
		if o.kind == &"defend_target": defend += 1
	var data_ok := errs.is_empty() and defend == 3 and st.hazards.size() == 2 and st.duration == 420.0
	print("  data validate=%s defend=%d hazards=%d" % [errs.is_empty(), defend, st.hazards.size()])

	# RunScene을 stage2로 구동.
	GameState.selected_stage_path = "res://data/stages/stage_musnyeo_village.tres"
	var rs := RunScene.new(); add_child(rs)
	await get_tree().physics_frame
	rs.set_physics_process(false)
	var sh_ok := rs._strongholds.size() == 3 and rs._hazards.size() == 2
	print("  run strongholds=%d hazards=%d" % [rs._strongholds.size(), rs._hazards.size()])
	# 몇 스텝 — 크래시 없이 진행 + 스폰.
	for _i in 40:
		rs._physics_process(0.1)
	var spawned := rs._enemies.active_count() > 0
	# 다중거점 패배: 한 거점 파괴 → lose.
	rs._strongholds[0].hp = 0.0
	rs._physics_process(0.1)
	var lose_ok := rs._result == ObjectiveEval.LOSE
	print("  spawned=%s lose_on_one_destroyed=%s" % [spawned, lose_ok])
	print("STAGE2 VERDICT => %s" % ["PASS" if (data_ok and sh_ok and spawned and lose_ok) else "FAIL"])
	get_tree().quit()

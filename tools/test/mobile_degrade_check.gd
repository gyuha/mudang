## 모바일 열화 스위치 검증(C4). active_limit 클램프 + GameState.low_spec 토글이 RunScene에 반영.
extends Node2D

func _ready() -> void:
	# 1) 직접 클램프: active_limit=250이면 300 스폰해도 250.
	var es := EnemySystem.new(); add_child(es)
	es.active_limit = 250
	var mob := load("res://data/enemies/mob_low.tres") as EnemyDef
	for i in 300:
		es.spawn(mob, Vector2(i, 0))
	var clamp_ok: bool = es.active_count() == 250
	print("  직접 클램프: 300 스폰 → active=%d (250 기대) %s" % [es.active_count(), clamp_ok])

	GameState.selected_companions = []
	GameState.selected_stage_path = "res://data/stages/stage_hwalinseo.tres"

	# 2) 통합: low_spec ON → RunScene active_limit=250.
	GameState.low_spec = true
	var rs_m := RunScene.new(); add_child(rs_m); rs_m.set_physics_process(false)
	var ml := rs_m._enemies.active_limit
	rs_m.queue_free()

	# 3) 통합: low_spec OFF → RunScene active_limit=CAP(512).
	GameState.low_spec = false
	var rs_p := RunScene.new(); add_child(rs_p); rs_p.set_physics_process(false)
	var pl := rs_p._enemies.active_limit
	rs_p.queue_free()

	var mobile_ok: bool = ml == GameState.MOBILE_ENEMY_CAP
	var pc_ok: bool = pl == EnemySystem.CAP
	print("  토글: low_spec ON→active_limit=%d(250 기대 %s) · OFF→%d(512 기대 %s)" % [ml, mobile_ok, pl, pc_ok])

	var pass_all: bool = clamp_ok and mobile_ok and pc_ok
	print("MOBILE_DEGRADE VERDICT => %s" % ["PASS" if pass_all else "FAIL"])
	get_tree().quit()

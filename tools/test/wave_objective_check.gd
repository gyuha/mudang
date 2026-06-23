## M6 스폰·목표 검증(S1~S4). WaveDirector(예산+타임라인)·거점 피해·승패 4분기를 판정.
## 6분 전체를 돌리지 않고 짧은 수동 스텝 + 순수 함수로 결정론적 판정(500@60fps GUI는 M-S).
extends Node2D

func _ready() -> void:
	var results := {}
	results["wave_spawn"] = _check_wave_spawn()
	results["stronghold"] = _check_stronghold()
	results["objective"] = _check_objective()

	var all := true
	for k in results:
		print("M6 %s => %s" % [k, "PASS" if results[k] else "FAIL"])
		all = all and results[k]
	print("M6 VERDICT => %s" % ["PASS" if all else "FAIL"])
	get_tree().quit()

# S1: WaveDirector가 예산으로 스폰하고 타임라인(t=90 ghost×8 등)이 정시 발동.
func _check_wave_spawn() -> bool:
	var e := EnemySystem.new(); add_child(e)
	var stage := load("res://data/stages/stage_hwalinseo.tres") as StageDef
	var wd := WaveDirector.new(); add_child(wd)
	wd.setup(stage, e, [Vector2(-300, 0), Vector2(300, 0), Vector2(0, 300)] as Array[Vector2])
	# t=0~50: 예산 스폰만(타임라인 첫 이벤트 t=90 전).
	var t := 0.0
	var dt := 0.5
	while t < 50.0:
		wd.tick(dt, t)
		t += dt
	var budget_ok := e.active_count() > 0 and wd.fired_count() == 0
	var c_before := e.active_count()
	# t=50~100: t=90 ghost group(8) 발동 통과.
	while t < 100.0:
		wd.tick(dt, t)
		t += dt
	var timeline_ok := wd.fired_count() >= 1 and e.active_count() >= c_before
	print("  wave_spawn t50_active=%d fired@100=%d active@100=%d" % [c_before, wd.fired_count(), e.active_count()])
	return budget_ok and timeline_ok

# S2: 거점 접촉피해로 HP 감소, 0이면 파괴.
func _check_stronghold() -> bool:
	var s := Stronghold.new(); add_child(s)
	var hp0 := s.hp           # 300
	s.take_contact_damage(100.0)
	var dropped := is_equal_approx(s.hp, hp0 - 100.0) and not s.is_destroyed()
	s.take_contact_damage(500.0)
	print("  stronghold %.0f -> %.0f destroyed=%s" % [hp0, s.hp, s.is_destroyed()])
	return dropped and s.is_destroyed()

# S3: 승패 판정 4분기.
func _check_objective() -> bool:
	var none := ObjectiveEval.evaluate(10.0, 360.0, 100.0, 300.0) == ObjectiveEval.NONE
	var win := ObjectiveEval.evaluate(360.0, 360.0, 100.0, 300.0) == ObjectiveEval.WIN
	var lose_m := ObjectiveEval.evaluate(10.0, 360.0, 0.0, 300.0) == ObjectiveEval.LOSE
	var lose_s := ObjectiveEval.evaluate(10.0, 360.0, 100.0, 0.0) == ObjectiveEval.LOSE
	print("  objective none=%s win=%s lose_mudang=%s lose_stronghold=%s" % [none, win, lose_m, lose_s])
	return none and win and lose_m and lose_s

## 던지는 통합 검증(M1 S4 기능). RunScene을 수동 스텝(dt 고정)으로 진행시켜
## 시간 경과에 따른 active_count(스폰/크랙 개방)·무녀 hp(추격+접촉)를 결정론적으로 표본화·판정.
## 시각/프레임 체감은 제외(GUI). (--quit-after는 프레임 단위라 실시간 의존 금지)
extends Node2D

func _ready() -> void:
	var rs := RunScene.new()
	add_child(rs)
	await get_tree().physics_frame      # rs._ready/_setup_spawn_points 완료
	rs.set_physics_process(false)        # 엔진 자동 호출 끄고 수동 스텝(중복 방지)

	var dt := 0.1
	var t := 0.0
	var c_early := -1
	var c_mid := -1
	var c_late := -1
	var hp_drop := false
	while t < 17.0:
		rs._physics_process(dt)          # run_time↑, 스폰, tick(이동), 접촉피해
		t += dt
		if rs._mudang.hp < Mudang.MAX_HP:
			hp_drop = true
		if c_early < 0 and t >= 2.0:
			c_early = rs._enemies.active_count()
			print("SPAWNFLOW t=2 active=%d hp=%.0f" % [c_early, rs._mudang.hp])
		elif c_mid < 0 and t >= 6.0:
			c_mid = rs._enemies.active_count()
			print("SPAWNFLOW t=6 active=%d hp=%.0f" % [c_mid, rs._mudang.hp])

	c_late = rs._enemies.active_count()
	print("SPAWNFLOW t=17 active=%d hp=%.0f" % [c_late, rs._mudang.hp])
	var spawn_ok := c_early > 0
	var grow_ok := c_mid >= c_early and c_late >= c_mid
	print("SPAWNFLOW VERDICT spawn(%s) grow(%s %d->%d->%d) hp_drop(%s) => %s" % [
		spawn_ok, grow_ok, c_early, c_mid, c_late, hp_drop,
		"PASS" if (spawn_ok and grow_ok and hp_drop) else "FAIL"])
	get_tree().quit()

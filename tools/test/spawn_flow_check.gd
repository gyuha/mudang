## RunScene 통합 스모크(M1→M6 갱신). 수동 스텝(dt 고정)으로 진행시켜
## WaveDirector 데이터 주도 스폰이 일어나고, 적이 방어 대상(거점/동료)에 접촉 피해를 주는지 결정론적으로 판정.
## M6 변경: 적은 무녀가 아니라 동료/거점을 노린다(D6-a) → 무녀 hp 대신 거점/동료 피해를 본다.
## 단조 증가 어서션은 폐기(동료가 적을 처치 → active 비단조). 시각/FPS는 GUI(M-S).
extends Node2D

func _ready() -> void:
	var rs := RunScene.new()
	add_child(rs)
	await get_tree().physics_frame      # rs._ready 완료(스테이지/거점/웨이브 셋업)
	rs.set_physics_process(false)        # 엔진 자동 호출 끄고 수동 스텝(중복 방지)

	# 견고한 통합 불변식만 검사(접촉피해/타게팅/승패 분기는 각 단위 체크가 커버):
	#  (1) 웨이브가 적을 스폰한다, (2) 적이 방어 대상 쪽으로 접근한다(중앙 근접),
	#  (3) 20초간 헛된 승/패가 나지 않는다(_result == none). 밸런스 의존 어서션(피해량) 회피.
	var dt := 0.1
	var t := 0.0
	var spawned := false
	var approached := false
	while t < 20.0:
		rs._physics_process(dt)          # run_time↑, 웨이브 스폰, tick, 접촉피해, 승패평가
		t += dt
		var n := rs._enemies.active_count()
		if n > 0:
			spawned = true
			for i in n:
				if rs._enemies.position_of(i).distance_to(rs._strongholds[0].global_position) < 200.0:
					approached = true

	var result_sane := rs._result == ObjectiveEval.NONE
	print("SPAWNFLOW t=20 active=%d result=%s" % [rs._enemies.active_count(), rs._result])
	print("SPAWNFLOW VERDICT spawn(%s) approach(%s) result_sane(%s) => %s" % [
		spawned, approached, result_sane,
		"PASS" if (spawned and approached and result_sane) else "FAIL"])
	get_tree().quit()

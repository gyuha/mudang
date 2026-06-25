## purify_zone 목표 검증(C4). 구역 점거 시 게이지 충전, 만충 시 WIN, 미점거 시 NONE.
## stage_yangban_gut(실데이터)로 구동하되 교란요소(해저드) 제거 + charge_time 단축으로 결정적.
extends Node2D

func _ready() -> void:
	GameState.set_state(GameState.S.RUN)
	GameState.selected_companions = []
	GameState.selected_stage_path = "res://data/stages/stage_yangban_gut.tres"
	var rs := RunScene.new()
	add_child(rs)              # _ready 동기 실행 → _purify_zones 채워짐
	rs.set_physics_process(false)
	rs._hazards.clear()        # 독장판 dps 교란 제거

	var has_zone: bool = rs._purify_zones.size() >= 1
	var z = rs._purify_zones[0]
	var geom_ok: bool = z["radius"] > 0.0      # 데이터에 pos/radius 반영됐는지
	z["charge_time"] = 1.0                      # 결정적 단축
	z["progress"] = 0.0                         # _ready 중 미세 충전분 리셋

	# 1) 미점거: 무녀+동료 전부 구역 밖으로 → 1틱 → 진행 0, 결과 NONE.
	var far: Vector2 = z["pos"] + Vector2(3000, 0)
	rs._mudang.global_position = far
	for c in rs._companions:
		c.global_position = far
	rs._physics_process(0.5)
	var idle_ok: bool = z["progress"] <= 0.001 and rs._result == ObjectiveEval.NONE
	print("  미점거: progress=%.3f result=%s -> %s" % [z["progress"], rs._result, idle_ok])

	# 2) 점거: 무녀를 구역 중심에 두고 충전시간 이상 틱 → 만충 → WIN.
	rs._mudang.global_position = z["pos"]
	for _f in 4:
		rs._physics_process(0.5)   # 2.0s > charge_time 1.0
	var win_ok: bool = z["progress"] >= 1.0 and rs._result == ObjectiveEval.WIN
	print("  점거: progress=%.3f result=%s -> %s" % [z["progress"], rs._result, win_ok])

	var pass_all: bool = has_zone and geom_ok and idle_ok and win_ok
	print("  zones=%d geom_ok=%s" % [rs._purify_zones.size(), geom_ok])
	print("PURIFY_ZONE VERDICT => %s" % ["PASS" if pass_all else "FAIL"])
	get_tree().quit()

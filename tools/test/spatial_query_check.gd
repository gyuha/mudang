## 던지는 검증(M1 S2): SpatialHash query_circle — 알려진 좌표 배치 시 반경 안/밖 경계. 헤드리스 전용.
extends Node2D

func _ready() -> void:
	var ok := true
	var es := EnemySystem.new()
	add_child(es)
	# ally_targets 비움 → tick이 격자만 재구축, 적은 이동 안 함(좌표 고정).
	var def := load("res://data/enemies/mob_low.tres") as EnemyDef

	# 알려진 좌표: 0=원점, 1=(50,0) 안, 2=(100,0) 경계, 3=(101,0) 밖.
	es.spawn(def, Vector2(0, 0))       # id 0
	es.spawn(def, Vector2(50, 0))      # id 1
	es.spawn(def, Vector2(100, 0))     # id 2 (경계, r=100)
	es.spawn(def, Vector2(101, 0))     # id 3 (밖)
	es.tick(0.0)  # dt=0: 격자 재구축만(아군 없음 → 이동 없음)

	var ids := es.query_circle(Vector2.ZERO, 100.0)
	var got := {}
	for i in ids:
		got[i] = true
	# 기대: {0,1,2}, 3 제외(거리 101 > 100).
	var pass_in := got.has(0) and got.has(1)
	var pass_boundary := got.has(2)         # 경계 포함(<=)
	var pass_out := not got.has(3)          # 밖 제외
	ok = pass_in and pass_boundary and pass_out
	print("S2.query: ids=%s expect{0,1,2}" % str(ids))
	print("S2.in(0,1)=%s boundary(2)=%s out(3 excluded)=%s" % [pass_in, pass_boundary, pass_out])
	print("S2: %s" % ("PASS" if ok else "FAIL"))
	get_tree().quit()

## 적 원거리 공격 검증(C3). ranged 적이 사거리에서 멈추고 접촉 없이 주기적으로 동료 HP를 깎는지.
extends Node2D

func _ready() -> void:
	var es := EnemySystem.new(); add_child(es)
	# 동료 1(원점, 비탱). 원거리 적의 타겟.
	var c := Companion.new(); c.def = load("res://data/companions/gyeonseup.tres"); add_child(c)
	c.position = Vector2(0, 0); c.hp = 200.0
	es.ally_targets = [c]

	var d := load("res://data/enemies/mask_spirit.tres") as EnemyDef  # ai_kind=ranged, attack_range=220
	var idx := es.spawn(d, Vector2(400, 0))
	var hp0 := c.hp

	# 8초 시뮬(접근 ~3.3s 후 사거리 정지 + 발사).
	for _f in 80:
		es.tick(0.1)

	var final_dist := es.position_of(idx).distance_to(c.global_position)
	var stopped_at_range: bool = final_dist > EnemySystem.CONTACT_RADIUS * 3 and final_dist <= d.attack_range + 8.0
	var damaged: bool = c.hp < hp0
	print("  ranged 적 최종거리=%.1f (사거리 %.0f, 접촉 %.0f) 정지유지=%s" % [final_dist, d.attack_range, EnemySystem.CONTACT_RADIUS, stopped_at_range])
	print("  동료 HP %.1f→%.1f 원거리피해=%s" % [hp0, c.hp, damaged])

	var pass_all: bool = stopped_at_range and damaged
	print("ENEMY_RANGED VERDICT => %s" % ["PASS" if pass_all else "FAIL"])
	get_tree().quit()

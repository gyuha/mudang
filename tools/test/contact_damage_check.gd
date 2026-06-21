## 던지는 검증(M1 S3): 무녀 인접 적 → 1s 접촉 시 HP 감소 = 접촉 적 수 × contact_damage. 헤드리스 전용.
extends Node2D

func _ready() -> void:
	var m := Mudang.new()
	add_child(m)
	m.position = Vector2.ZERO
	var es := EnemySystem.new()
	add_child(es)
	es.ally_targets = [m]
	var def := load("res://data/enemies/mob_low.tres") as EnemyDef

	# 무녀 인접(접촉 반경 내)에 적 2마리.
	es.spawn(def, Vector2(4, 0))
	es.spawn(def, Vector2(-4, 0))

	var hp0: float = m.hp
	var dt := 0.1
	var steps := 10  # 총 1.0s
	for _i in steps:
		es.tick(dt)
		var contacts := es.query_circle(m.global_position, EnemySystem.CONTACT_RADIUS)
		if contacts.size() > 0:
			m.take_contact_damage(def.contact_damage * contacts.size() * dt)

	var drop: float = hp0 - m.hp
	var expect := def.contact_damage * 2.0 * 1.0  # 4 * 2마리 * 1s = 8
	var ok: bool = abs(drop - expect) < 0.001
	print("S3.contact: HP %.1f -> %.1f drop=%.2f expect=%.2f (2 enemies x %.0f/s x 1s) -> %s" % [
		hp0, m.hp, drop, expect, def.contact_damage, "PASS" if ok else "FAIL"
	])
	print("S3: %s" % ("PASS" if ok else "FAIL"))
	get_tree().quit()

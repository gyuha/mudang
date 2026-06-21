## 던지는 검증(M1 S1): EnemySystem 풀 — 상한 클램프 + apply_damage 슬롯 회수. 헤드리스 전용.
extends Node2D

func _ready() -> void:
	var ok := true
	var es := EnemySystem.new()
	add_child(es)
	var def := load("res://data/enemies/mob_low.tres") as EnemyDef

	# 1) 상한 초과 spawn → active_count == min(N, CAP).
	var n := EnemySystem.CAP + 25
	for i in n:
		es.spawn(def, Vector2(i * 5, 0))
	var ac := es.active_count()
	var expect: int = min(n, EnemySystem.CAP)
	var pass1: bool = ac == expect
	ok = ok and pass1
	print("S1.cap: spawn(%d) -> active=%d expect=%d -> %s" % [n, ac, expect, "PASS" if pass1 else "FAIL"])

	# 2) apply_damage로 HP0 처치 → 슬롯 1개 회수(active_count -1).
	var before := es.active_count()
	es.apply_damage(0, def.max_hp)  # mob_low max_hp=6, 6 데미지로 처치
	var after := es.active_count()
	var pass2 := after == before - 1
	ok = ok and pass2
	print("S1.free: kill 1 -> active %d -> %d expect %d -> %s" % [before, after, before - 1, "PASS" if pass2 else "FAIL"])

	# 3) 회수 후 재스폰 시 새 슬롯 할당 없이 active 복귀.
	es.spawn(def, Vector2(9999, 0))
	var pass3 := es.active_count() == before
	ok = ok and pass3
	print("S1.reuse: respawn -> active=%d expect=%d -> %s" % [es.active_count(), before, "PASS" if pass3 else "FAIL"])

	print("S1: %s" % ("PASS" if ok else "FAIL"))
	get_tree().quit()

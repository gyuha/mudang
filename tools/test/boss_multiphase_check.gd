## 보스 다페이즈 검증(C2). HP 임계 하향 시 (1) 이동속도 escalation, (2) 전환 1회 소환.
extends Node2D

func _ready() -> void:
	var es := EnemySystem.new(); add_child(es)
	# 보스가 향할 더미 타겟(멀리).
	var tgt := Node2D.new(); tgt.position = Vector2(1000, 0); add_child(tgt)
	es.ally_targets = [tgt]

	var boss := load("res://data/enemies/boss_royal_wraith.tres") as EnemyDef  # summon mob_low ×4
	var idx := es.spawn(boss, Vector2(0, 0))

	# 1) 만HP(페이즈0) 1틱 이동량.
	var x0 := es.position_of(idx).x
	es.tick(0.1)
	var d_full := es.position_of(idx).x - x0
	var count_before := es.active_count()   # 보스 1

	# HP를 30%로 → 다음 틱에서 페이즈2(속도↑ + 전환 소환).
	es.apply_damage(idx, boss.max_hp * 0.7)
	var x1 := es.position_of(idx).x
	es.tick(0.1)
	var d_low := es.position_of(idx).x - x1
	var count_after := es.active_count()     # 보스 + 소환

	var speed_ok: bool = d_low > d_full * 1.2     # 1.5배 escalation 기대
	var summoned := count_after - count_before
	var summon_ok: bool = summoned >= boss.summon_count
	print("  이동량: 만HP=%.2f 저HP(p2)=%.2f escalation=%s" % [d_full, d_low, speed_ok])
	print("  소환: active %d→%d (+%d, summon_count=%d) %s" % [count_before, count_after, summoned, boss.summon_count, summon_ok])

	var pass_all: bool = speed_ok and summon_ok
	print("BOSS_MULTIPHASE VERDICT => %s" % ["PASS" if pass_all else "FAIL"])
	get_tree().quit()

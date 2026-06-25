## 적 AI 거동 분화 검증(C2). enemy_system이 ai_kind별로 다른 타겟을 고르는지.
## 배치: 거점(근접) + 동료A(중거리·고HP) + 동료B(원거리·저HP). 비탱 동료로 taunt 간섭 배제.
extends Node2D

func _ready() -> void:
	var es := EnemySystem.new(); add_child(es)

	# 거점: 원점에서 가장 가까움(30).
	var sh := Stronghold.new(); add_child(sh); sh.position = Vector2(30, 0); sh.hp = 300.0
	# 동료A: 중거리(100), 고HP. 견습무당(taunt 0).
	var ca := Companion.new(); ca.def = load("res://data/companions/gyeonseup.tres"); add_child(ca); ca.position = Vector2(100, 0); ca.hp = 120.0
	# 동료B: 원거리(-300), 저HP. 활잡이(taunt 0).
	var cb := Companion.new(); cb.def = load("res://data/companions/hwaljabi.tres"); add_child(cb); cb.position = Vector2(-300, 0); cb.hp = 10.0
	es.ally_targets = [sh, ca, cb]

	var origin := Vector2.ZERO
	var d_rush := load("res://data/enemies/mob_low.tres") as EnemyDef       # rush_companion
	var d_tgt := load("res://data/enemies/ghost_maiden.tres") as EnemyDef   # target_companion
	var d_low := load("res://data/enemies/changgwi.tres") as EnemyDef       # rush_lowhp

	var t_rush := es._nearest_target(origin, d_rush)   # 최근접 아군 = 거점(30)
	var t_tgt := es._nearest_target(origin, d_tgt)     # 최근접 동료 = ca(100), 거점 무시
	var t_low := es._nearest_target(origin, d_low)     # 최저HP 동료 = cb(-300)

	var rush_ok: bool = t_rush.is_equal_approx(sh.position)
	var tgt_ok: bool = t_tgt.is_equal_approx(ca.position)
	var low_ok: bool = t_low.is_equal_approx(cb.position)
	print("  rush_companion → %s (거점 %s) %s" % [t_rush, sh.position, rush_ok])
	print("  target_companion → %s (동료A %s) %s" % [t_tgt, ca.position, tgt_ok])
	print("  rush_lowhp → %s (저HP동료B %s) %s" % [t_low, cb.position, low_ok])

	# 통합: rush_lowhp 적 스폰 후 tick → 저HP 동료(음수 x) 방향으로 이동(분기가 tick에서도 작동).
	var idx := es.spawn(d_low, origin)
	es.tick(0.1)
	var moved_neg: bool = es.position_of(idx).x < 0.0
	print("  tick: rush_lowhp 적 x=%.2f (<0 기대) %s" % [es.position_of(idx).x, moved_neg])

	var pass_all: bool = rush_ok and tgt_ok and low_ok and moved_neg
	print("ENEMY_AI_KIND VERDICT => %s" % ["PASS" if pass_all else "FAIL"])
	get_tree().quit()

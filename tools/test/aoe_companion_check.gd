## 광역 동료 탈쓴퇴마사 검증(C3). aoe role의 광역 베기가 반경 내 적 다수 동시 타격.
extends Node2D

func _ready() -> void:
	var es := EnemySystem.new(); add_child(es)
	var mob := load("res://data/enemies/mob_low.tres") as EnemyDef   # 6hp
	es.spawn(mob, Vector2(0, 0))
	es.spawn(mob, Vector2(15, 0))
	es.spawn(mob, Vector2(30, 0))
	es.tick(0.0)   # spatial hash 빌드(실게임은 매 프레임 tick 후 동료가 공격)
	var before := es.active_count()

	var c := Companion.new()
	c.def = load("res://data/companions/talchum.tres")
	c.enemies = es
	add_child(c)                       # _ready: def = def.duplicate()
	c.position = Vector2(60, 0)

	var role_ok: bool = c.def.role_id == &"aoe" and c.def.aoe_radius > 0.0
	var sprite_ok: bool = ResourceLoader.exists("res://assets/sprites/talchum.png")

	# 광역 베기 1회: 타겟(0번, 군집) 주변 반경 내 적 다수 동시 타격.
	c._target_idx = 0
	c._attack_accum = c.def.attack_period   # 쿨다운 충족 → 발사
	c._try_attack(0.0)                       # dist 0 <= attack_range
	var after := es.active_count()
	var multi_hit: bool = (before - after) >= 2

	print("  role=%s aoe_radius=%.0f sprite=%s" % [c.def.role_id, c.def.aoe_radius, sprite_ok])
	print("  active %d→%d (광역 처치 %d, ≥2 기대) multi=%s" % [before, after, before - after, multi_hit])

	var pass_all: bool = role_ok and sprite_ok and multi_hit
	print("AOE_COMPANION VERDICT => %s" % ["PASS" if pass_all else "FAIL"])
	get_tree().quit()

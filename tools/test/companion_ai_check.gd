## M2 동료 AI 통합 검증(S1~S6). 격리된 셋업을 수동 스텝(dt 고정)으로 진행시켜
## 획득·전투·카이팅·도발·분리·leash·힐을 결정론적으로 판정. 시각/프레임 체감은 제외(GUI).
## 각 거동을 독립 EnemySystem/Companion으로 구성(풀 상태 격리). M1 tools/test 패턴.
extends Node2D

func _ready() -> void:
	var results := {}
	results["load"] = _check_load()
	results["acquire_attack"] = _check_acquire_attack()
	results["kite"] = _check_kite()
	results["taunt"] = _check_taunt()
	results["separation"] = _check_separation()
	results["leash"] = _check_leash()
	results["heal"] = _check_heal()

	var all := true
	for k in results:
		print("COMPANION %s => %s" % [k, "PASS" if results[k] else "FAIL"])
		all = all and results[k]
	print("COMPANION VERDICT => %s" % ["PASS" if all else "FAIL"])
	get_tree().quit()

# --- 헬퍼 ---

func _fresh_enemies() -> EnemySystem:
	var e := EnemySystem.new()
	add_child(e)
	return e

func _make_companion(path: String) -> Companion:
	var c := Companion.new()
	c.def = load(path) as CompanionDef
	add_child(c)   # _ready → hp = max_hp
	return c

# S1: 3 .tres 로드 + role_id/주요 스탯이 docs/09 값과 일치.
func _check_load() -> bool:
	var h := load("res://data/companions/hwarang.tres") as CompanionDef
	var a := load("res://data/companions/hwaljabi.tres") as CompanionDef
	var g := load("res://data/companions/gyeonseup.tres") as CompanionDef
	if h == null or a == null or g == null:
		return false
	var ok := (
		h.role_id == &"tank" and h.max_hp == 120.0 and h.taunt_radius == 120.0
		and a.role_id == &"ranged" and a.attack_range == 320.0 and a.kite_min == 80.0
		and g.role_id == &"healer" and g.attack_damage == 0.0 and g.heal_per_sec == 6.0
	)
	print("  load tank=%s ranged=%s healer=%s" % [h.role_id, a.role_id, g.role_id])
	return ok

# S2+S3: 탱이 최근접 적을 획득→접근→공격해 처치(active_count 1→0).
func _check_acquire_attack() -> bool:
	var e := _fresh_enemies()
	var mud := Node2D.new(); add_child(mud); mud.position = Vector2.ZERO
	var tank := _make_companion("res://data/companions/hwarang.tres")
	tank.position = Vector2.ZERO
	tank.enemies = e
	tank.mudang = mud
	tank.allies = [tank]
	var mob := load("res://data/enemies/mob_low.tres") as EnemyDef
	e.ally_targets = [tank]
	e.spawn(mob, Vector2(200, 0))
	var start := e.active_count()
	var dt := 0.05
	var t := 0.0
	while t < 6.0 and e.active_count() > 0:
		e.tick(dt)
		tank.step(dt)
		t += dt
	print("  acquire_attack start=%d end=%d t=%.1f" % [start, e.active_count(), t])
	return start == 1 and e.active_count() == 0

# S3: 원딜이 kite_min 안 적에게서 후퇴(카이팅)하며 사격해 처치.
func _check_kite() -> bool:
	var e := _fresh_enemies()
	var mud := Node2D.new(); add_child(mud); mud.position = Vector2(-300, 0)
	var arch := _make_companion("res://data/companions/hwaljabi.tres")
	arch.position = Vector2.ZERO
	arch.enemies = e
	arch.mudang = mud
	arch.allies = [arch]
	var mob := load("res://data/enemies/mob_low.tres") as EnemyDef
	e.ally_targets = []   # 적 정지 — 카이팅 변위만 측정
	e.spawn(mob, Vector2(50, 0))   # kite_min(80) 안
	var dt := 0.05
	var t := 0.0
	var min_x := 0.0
	while t < 3.0:
		e.tick(dt)
		arch.step(dt)
		min_x = min(min_x, arch.position.x)
		t += dt
	# 후퇴(왼쪽, 적 반대) + 사격으로 처치.
	print("  kite min_x=%.0f killed=%s" % [min_x, e.active_count() == 0])
	return min_x < -10.0 and e.active_count() == 0

# S4: 도발 반경 안 적이 더 가까운 비탱 대신 탱을 노린다.
func _check_taunt() -> bool:
	var e := _fresh_enemies()
	var tank := _make_companion("res://data/companions/hwarang.tres")
	tank.position = Vector2(0, 0)
	var arch := _make_companion("res://data/companions/hwaljabi.tres")
	arch.position = Vector2(0, 100)
	var mob := load("res://data/enemies/mob_low.tres") as EnemyDef
	e.ally_targets = [tank, arch]
	# (60,60): 탱까지 84.8(<도발120), 활잡이까지 72.1 → 도발 없으면 활잡이가 최근접.
	var idx := e.spawn(mob, Vector2(60, 60))
	var d_tank_before := e.position_of(idx).distance_to(tank.position)
	e.tick(0.1)
	var d_tank_after := e.position_of(idx).distance_to(tank.position)
	print("  taunt d_tank %.1f -> %.1f" % [d_tank_before, d_tank_after])
	# 도발이 먹히면 적은 (더 가까운 활잡이가 아니라) 탱 쪽으로 이동 → 탱과의 거리 감소.
	return d_tank_after < d_tank_before

# S5: 겹친 두 동료가 separation으로 서로 밀려난다(무녀 없음 → leash/재집결 영향 배제).
func _check_separation() -> bool:
	var a := _make_companion("res://data/companions/hwarang.tres")
	var b := _make_companion("res://data/companions/hwarang.tres")
	a.position = Vector2(0, 0)
	b.position = Vector2(5, 0)
	a.allies = [a, b]
	b.allies = [a, b]
	# enemies/mudang 미설정(null) → 타겟 없음 + leash/재집결 없음, 분리력만.
	var before := a.position.distance_to(b.position)
	var dt := 0.05
	for _i in 30:
		a.step(dt)
		b.step(dt)
	var after := a.position.distance_to(b.position)
	print("  separation dist %.1f -> %.1f" % [before, after])
	return after > before

# S5: leash_radius 밖 동료가 무녀 쪽으로 당겨진다.
func _check_leash() -> bool:
	var mud := Node2D.new(); add_child(mud); mud.position = Vector2.ZERO
	var tank := _make_companion("res://data/companions/hwarang.tres")
	tank.position = Vector2(500, 0)   # leash_radius 360 밖
	tank.mudang = mud
	tank.allies = [tank]
	# enemies 미설정 → 타겟 없음, leash로만 복귀.
	var before := tank.position.distance_to(mud.position)
	var dt := 0.05
	for _i in 20:
		tank.step(dt)
	var after := tank.position.distance_to(mud.position)
	print("  leash dist %.0f -> %.0f" % [before, after])
	return after < before

# S3: 힐러가 반경 내 부상 아군의 HP를 회복시킨다.
func _check_heal() -> bool:
	var healer := _make_companion("res://data/companions/gyeonseup.tres")
	healer.position = Vector2(0, 0)
	var tank := _make_companion("res://data/companions/hwarang.tres")
	tank.position = Vector2(50, 0)   # heal_radius 140 안
	tank.hp = 10.0                    # 부상
	healer.allies = [healer, tank]
	tank.allies = [healer, tank]
	# enemies/mudang 미설정 → 외부 피해 없음, 힐 효과만 측정.
	var before := tank.hp
	var dt := 0.05
	for _i in 40:   # 2초
		healer.step(dt)
		tank.step(dt)
	print("  heal tank hp %.1f -> %.1f" % [before, tank.hp])
	return tank.hp > before

## 스테이지1 데이터 시드/검증용 EditorScript.
## 사용: Godot 에디터에서 이 파일 열고 File > Run (Ctrl+Shift+X).
## 손작성 .tres가 포맷 문제로 안 열리면, 이 스크립트가 동일 데이터를 코드로 빌드해
## res://data/ 에 정식 .tres로 재생성하고 validate() 결과를 출력한다.
## (도구 검증 전 단계의 시드 — [docs/05]§4 "1단계: 도구 없음" 정신)
@tool
extends EditorScript

func _build_enemy(id: StringName, hp: float, spd: float, resist: float, dmg: float,
		ai: StringName, cost: int, exp_v: int, lvl: int,
		md_ch: float, md_amt: int, co_ch: float, co_amt: int) -> EnemyDef:
	var e := EnemyDef.new()
	e.id = id
	e.max_hp = hp
	e.move_speed = spd
	e.knockback_resist = resist
	e.contact_damage = dmg
	e.ai_kind = ai
	e.spawn_cost = cost
	e.exp_value = exp_v
	e.level = lvl
	var d := DropTable.new()
	d.mudang_soulfire_chance = md_ch
	d.mudang_soulfire_amount = md_amt
	d.companion_soulfire_chance = co_ch
	d.companion_soulfire_amount = co_amt
	e.drop = d
	return e

func _spawn(enemy: EnemyDef, w: float, t0: float, t1: float) -> SpawnPoolEntry:
	var s := SpawnPoolEntry.new()
	s.enemy = enemy; s.weight = w; s.start_time = t0; s.end_time = t1
	return s

func _event(t: float, kind: int, enemy: EnemyDef, count: int) -> TimelineEvent:
	var ev := TimelineEvent.new()
	ev.time = t; ev.kind = kind; ev.enemy = enemy; ev.count = count
	return ev

func _objective(kind: StringName, params: Dictionary) -> ObjectiveDef:
	var o := ObjectiveDef.new()
	o.kind = kind; o.params = params
	return o

func _save(res: Resource, path: String) -> void:
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var err := ResourceSaver.save(res, path)
	print("save %s -> %s" % [path, "OK" if err == OK else "ERR %d" % err])

func _run() -> void:
	# 적 4종 ([docs/09]§2)
	var mob := _build_enemy(&"mob_low", 6, 70, 0.1, 4, &"rush_companion", 1, 1, 1, 0.6, 1, 0.4, 1)
	var ghost := _build_enemy(&"ghost_maiden", 10, 130, 0.2, 6, &"target_companion", 3, 2, 1, 0.7, 1, 0.3, 2)
	var dok := _build_enemy(&"dokkaebi", 90, 45, 0.7, 14, &"elite", 12, 8, 1, 1.0, 2, 1.0, 5)
	var boss := _build_enemy(&"boss_hwalinseo", 1200, 50, 0.85, 22, &"boss", 0, 40, 3, 1.0, 10, 1.0, 15)
	_save(mob, "res://data/enemies/mob_low.tres")
	_save(ghost, "res://data/enemies/ghost_maiden.tres")
	_save(dok, "res://data/enemies/dokkaebi.tres")
	_save(boss, "res://data/enemies/boss_hwalinseo.tres")

	# 스테이지1 ([docs/09]§5, [docs/10]§6)
	var st := StageDef.new()
	st.id = &"stage_hwalinseo"
	st.display_name = "1장 활인서의 밤"
	st.duration = 360.0
	st.objectives = [
		_objective(&"survive_time", {"time": 360.0}),
		_objective(&"defend_target", {"target_hp": 300.0, "label": "병자 거점"}),
	]
	st.spawn_pool = [
		_spawn(mob, 1.0, 0.0, -1.0),
		_spawn(ghost, 0.6, 120.0, -1.0),
	]
	st.timeline = [
		_event(90.0, TimelineEvent.Kind.SPAWN_GROUP, ghost, 8),
		_event(180.0, TimelineEvent.Kind.MINIBOSS, dok, 1),
		_event(300.0, TimelineEvent.Kind.RUSH, mob, 40),
		_event(300.0, TimelineEvent.Kind.RUSH, ghost, 10),
		_event(360.0, TimelineEvent.Kind.MINIBOSS, boss, 1),
	]
	st.budget_base = 2.0
	st.budget_growth_per_sec = 0.0333
	st.max_active_enemies = 500
	st.soulfire_ratio = 0.6
	st.recommended_roles = [&"tank", &"healer"]
	var rw := StageReward.new()
	rw.meta_currency = 50
	rw.first_clear_bonus = 100
	st.reward = rw
	_save(st, "res://data/stages/stage_hwalinseo.tres")

	var errs := st.validate()
	print("validate(stage_hwalinseo): ", "PASS" if errs.is_empty() else errs)

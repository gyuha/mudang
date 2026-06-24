## 아트 에셋 완비 검증(C5). 6스테이지 배경 + 타이틀 + 모든 EnemyDef/CompanionDef 참조 스프라이트.
## 규약: 배경 res://assets/bg/<StageDef.id>.png, 스프라이트 res://assets/sprites/<def.id>.png.
extends Node2D

func _ready() -> void:
	var missing: Array[String] = []

	# --- 6스테이지 배경 ---
	var stage_ids := ["stage_hwalinseo", "stage_musnyeo_village", "stage_mountain_pass",
		"stage_yangban_gut", "stage_seonsucheong", "stage_palace_wraith"]
	var bg_ok := 0
	for sid in stage_ids:
		var p := "res://assets/bg/%s.png" % sid
		if ResourceLoader.exists(p): bg_ok += 1
		else: missing.append(p)
	print("  stage bg %d/6" % bg_ok)

	# --- 타이틀/대시보드 배경 ---
	var title_ok := ResourceLoader.exists("res://assets/bg/title_bg.png")
	if not title_ok: missing.append("res://assets/bg/title_bg.png")
	print("  title_bg=%s" % title_ok)

	# --- EnemyDef 스프라이트(전수) ---
	var enemy_ok := 0
	var enemy_n := 0
	for f in _list("res://data/enemies"):
		var def := load(f) as EnemyDef
		if def == null: continue
		enemy_n += 1
		var p := "res://assets/sprites/%s.png" % def.id
		if ResourceLoader.exists(p): enemy_ok += 1
		else: missing.append(p)
	print("  enemy sprites %d/%d" % [enemy_ok, enemy_n])

	# --- CompanionDef 스프라이트(전수) ---
	var comp_ok := 0
	var comp_n := 0
	for f in _list("res://data/companions"):
		var def := load(f) as CompanionDef
		if def == null: continue
		comp_n += 1
		var p := "res://assets/sprites/%s.png" % def.id
		if ResourceLoader.exists(p): comp_ok += 1
		else: missing.append(p)
	print("  companion sprites %d/%d" % [comp_ok, comp_n])

	var pass_all: bool = missing.is_empty() and bg_ok == 6 and title_ok and enemy_n > 0 and comp_n > 0
	if not missing.is_empty():
		print("  MISSING: %s" % str(missing))
	print("ART_ASSETS VERDICT => %s" % ["PASS" if pass_all else "FAIL"])
	get_tree().quit()

## .tres 파일 목록(절대 res:// 경로).
func _list(dir_path: String) -> Array[String]:
	var out: Array[String] = []
	var d := DirAccess.open(dir_path)
	if d == null: return out
	d.list_dir_begin()
	var name := d.get_next()
	while name != "":
		if not d.current_is_dir() and name.ends_with(".tres"):
			out.append("%s/%s" % [dir_path, name])
		name = d.get_next()
	d.list_dir_end()
	return out

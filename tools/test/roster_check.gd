## 후속 적 로스터 검증. 창귀/역병귀/탈귀 EnemyDef 로드 + 스탯(docs/04§1) + EnemySystem 스폰 시 스프라이트.
extends Node2D
func _ready() -> void:
	var ids: Array[String] = ["changgwi", "plague", "mask_spirit"]
	var hps: Array[float] = [18.0, 25.0, 20.0]
	var spds: Array[float] = [150.0, 60.0, 55.0]
	var ok := true
	var e := EnemySystem.new()
	add_child(e)
	for i in ids.size():
		var d: EnemyDef = load("res://data/enemies/%s.tres" % ids[i]) as EnemyDef
		var stat_ok: bool = d != null and d.max_hp == hps[i] and d.move_speed == spds[i] and d.sprite_size > 0.0
		var idx: int = e.spawn(d, Vector2(spds[i], 0.0))
		print("  %s stat_ok=%s spawned=%s" % [ids[i], stat_ok, idx >= 0])
		ok = ok and stat_ok and idx >= 0
	var tex_ok := false
	for ch in e.get_children():
		# 적 렌더는 MultiMesh 백엔드(M-S) — 텍스처별 MultiMeshInstance2D.texture로 로드 확인.
		if (ch is Sprite2D or ch is MultiMeshInstance2D) and ch.texture != null:
			tex_ok = true
	print("  enemy sprites loaded=%s" % tex_ok)
	print("ROSTER VERDICT => %s" % ["PASS" if (ok and tex_ok) else "FAIL"])
	get_tree().quit()

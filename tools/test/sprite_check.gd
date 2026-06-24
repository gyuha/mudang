## 유닛 스프라이트 와이어링 검증. 무녀·동료(Sprite2D)·적(MultiMesh 백엔드, M-S)이 텍스처를 실제 로드해 렌더에 붙였는지.
## 시각 적합성은 GUI — 여기선 "텍스처가 실제로 로드돼 렌더 노드에 붙었는가"만. (적은 MultiMeshInstance2D.texture)
extends Node2D

func _ready() -> void:
	var ok := true
	var m := Mudang.new(); add_child(m)
	ok = _has_sprite(m, "mudang") and ok
	for id in ["hwarang", "hwaljabi", "gyeonseup"]:
		var c := Companion.new()
		c.def = load("res://data/companions/%s.tres" % id) as CompanionDef
		add_child(c)
		ok = _has_sprite(c, id) and ok
	# 적 풀 스프라이트: mob 1마리 스폰 후 텍스처 부착 확인.
	var e := EnemySystem.new(); add_child(e)
	e.spawn(load("res://data/enemies/mob_low.tres") as EnemyDef, Vector2.ZERO)
	ok = _has_sprite(e, "enemy:mob_low") and ok
	print("SPRITE VERDICT => %s" % ["PASS" if ok else "FAIL"])
	get_tree().quit()

func _has_sprite(node: Node, label: String) -> bool:
	for ch in node.get_children():
		# Sprite2D(무녀·동료) 또는 MultiMeshInstance2D(적 배치 렌더) — 둘 다 .texture로 로드 확인.
		if (ch is Sprite2D or ch is MultiMeshInstance2D) and ch.texture != null:
			print("  %s tex=%dx%d (%s)" % [label, ch.texture.get_width(), ch.texture.get_height(), ch.get_class()])
			return true
	print("  %s NO texture (fallback?)" % label)
	return false

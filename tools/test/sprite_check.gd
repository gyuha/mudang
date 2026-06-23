## 유닛 스프라이트 와이어링 검증. 무녀·동료가 ColorRect 폴백이 아니라 Sprite2D(텍스처 로드)를 쓰는지.
## 시각 적합성은 GUI — 여기선 "텍스처가 실제로 로드돼 스프라이트로 붙었는가"만.
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
		if ch is Sprite2D and ch.texture != null:
			print("  %s sprite=%dx%d" % [label, ch.texture.get_width(), ch.texture.get_height()])
			return true
	print("  %s NO sprite (fallback?)" % label)
	return false

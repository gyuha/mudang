## 미니맵 검증. world→minimap 변환(코너/중심 매핑)이 정확한지. 렌더는 GUI.
extends Node2D
func _ready() -> void:
	var mm := MinimapHUD.new(); add_child(mm)
	var H := MinimapHUD.ARENA_HALF
	var S := MinimapHUD.MINI_SIZE
	var c0 := mm.world_to_mini(Vector2(-H, -H))      # 좌상 → (0,0)
	var c1 := mm.world_to_mini(Vector2(H, H))        # 우하 → (S,S)
	var cc := mm.world_to_mini(Vector2.ZERO)         # 중심 → (S/2,S/2)
	var ok := c0.is_equal_approx(Vector2.ZERO) \
		and c1.is_equal_approx(Vector2(S, S)) \
		and cc.is_equal_approx(Vector2(S, S) * 0.5)
	print("MINIMAP c0=%s c1=%s cc=%s" % [c0, c1, cc])
	print("MINIMAP VERDICT => %s" % ["PASS" if ok else "FAIL"])
	get_tree().quit()

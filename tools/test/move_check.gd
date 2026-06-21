## 던지는 검증 스크립트(M0 S3 이동 로직). 헤드리스 전용. autoload 로드 위해 씬으로 실행.
extends Node2D
func _ready() -> void:
	var ia := get_node_or_null("/root/InputAdapter")
	if ia == null:
		print("MOVECHECK: FAIL - no InputAdapter autoload")
		get_tree().quit(); return
	var m := Mudang.new()
	add_child(m)
	var p0: Vector2 = m.position
	ia.move_vector = Vector2(1, 0)
	m._physics_process(0.5)  # 220 * 0.5 = 110
	var dx: float = m.position.x - p0.x
	print("MOVECHECK: dx=%.2f (expect ~110)" % dx)
	get_tree().quit()

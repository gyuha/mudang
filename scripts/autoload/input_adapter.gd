## 입력 추상 레이어 (D5). autoload로 등록(`InputAdapter`). ([docs/01]§1)
## 플랫폼 분기는 여기서만. 게임 로직은 아래 추상 3종만 읽는다.
## 모바일 이식 시 이 어댑터 1개만 교체(가상 조이스틱 + 터치 unproject).
## NOTE: autoload명 `InputAdapter`와 class_name 충돌 회피 위해 class_name 미선언. 전역 접근은 autoload명으로.
extends Node

## 무녀 이동 방향(정규화). PC: WASD ([docs/01]§1)
var move_vector: Vector2 = Vector2.ZERO
## 넉백 시전 위치(월드 좌표). PC: 마우스 좌표
var aim_point: Vector2 = Vector2.ZERO
## 「물렀거라」 시전 입력(이번 프레임 눌림)
var aim_pressed: bool = false
## 「모여라」 트리거(이번 프레임 눌림). PC: 스페이스/우클릭 ([docs/01]§1)
var rally_pressed: bool = false

func _process(_delta: float) -> void:
	move_vector = Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	# NOTE: aim_point는 활성 Camera2D 기준 마우스 월드 좌표. 카메라가 없으면 화면 좌표로 폴백.
	#       in-editor에서 카메라 추적 시 좌표가 맞는지 확인할 것.
	var vp := get_viewport()
	var cam := vp.get_camera_2d()
	if cam != null:
		aim_point = cam.get_global_mouse_position()
	else:
		aim_point = vp.get_mouse_position()
	aim_pressed = Input.is_action_just_pressed(&"aim")
	rally_pressed = Input.is_action_just_pressed(&"rally")

## 미니맵 HUD (docs/08 §6). 화면 밖 동료/거점/보스 위치·상태를 한눈에. 정보 전용(상호작용 없음).
## world→minimap 변환은 순수 함수(헤드리스 검증). 렌더(_draw)는 GUI. 잡몹 개별 점 금지(§6.2).
class_name MinimapHUD
extends Control

## 미니맵 한 변 px.
const MINI_SIZE: float = 140.0
## 월드 [-ARENA_HALF, ARENA_HALF]² 가 미니맵 [0, MINI_SIZE]² 로 매핑(경계 아레나 가정 §6.1).
const ARENA_HALF: float = 700.0

var mudang: Node2D
var companions: Array = []
var strongholds: Array = []
var enemies: EnemySystem

func _ready() -> void:
	custom_minimum_size = Vector2(MINI_SIZE, MINI_SIZE)
	# 우상단 고정(§6.1 기본).
	set_anchors_preset(Control.PRESET_TOP_RIGHT)
	position = Vector2(-MINI_SIZE - 8.0, 8.0)

## 월드 좌표 → 미니맵 로컬 좌표(순수 — 헤드리스 검증용). §6.1
func world_to_mini(w: Vector2) -> Vector2:
	return (w + Vector2(ARENA_HALF, ARENA_HALF)) / (ARENA_HALF * 2.0) * MINI_SIZE

func _process(_dt: float) -> void:
	queue_redraw()

func _role_color(role_id: StringName) -> Color:
	match role_id:
		&"tank": return Color(0.30, 0.55, 0.95)
		&"ranged": return Color(0.40, 0.85, 0.45)
		&"healer": return Color(0.95, 0.90, 0.55)
		_: return Color(0.8, 0.8, 0.8)

func _draw() -> void:
	# 프레임(반투명 배경 + 테두리).
	draw_rect(Rect2(Vector2.ZERO, Vector2(MINI_SIZE, MINI_SIZE)), Color(0.05, 0.05, 0.08, 0.6))
	draw_rect(Rect2(Vector2.ZERO, Vector2(MINI_SIZE, MINI_SIZE)), Color(0.8, 0.7, 0.5, 0.7), false, 1.5)
	# 거점(다중, HP 색: 녹→적).
	for sh in strongholds:
		if sh == null:
			continue
		var r: float = clampf(sh.hp / sh.max_hp, 0.0, 1.0)
		draw_rect(Rect2(world_to_mini(sh.global_position) - Vector2(3, 3), Vector2(6, 6)),
			Color(0.85, 0.2, 0.2).lerp(Color(0.3, 0.85, 0.3), r))
	# 보스/엘리트(sprite_size 큰 적만 — 잡귀 개별 점 금지 §6.2).
	if enemies != null:
		for i in enemies.active_count():
			if enemies.def_of(i).sprite_size >= 60.0:
				draw_circle(world_to_mini(enemies.position_of(i)), 3.5, Color(0.9, 0.3, 0.85))
	# 동료(역할 색, 쓰러짐=적색 §6.3).
	for c in companions:
		if c == null or c.def == null:
			continue
		var col := Color(0.9, 0.2, 0.2) if c.is_incapacitated() else _role_color(c.def.role_id)
		draw_circle(world_to_mini(c.global_position), 2.5, col)
	# 무녀(중심 흰/금 아이콘).
	if mudang != null:
		draw_circle(world_to_mini(mudang.global_position), 3.0, Color(1, 0.95, 0.7))

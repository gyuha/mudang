## HP 스테이터스 바(HUD 슬라이스) — 유닛 머리 위 월드 공간 체력 바. ([docs/08]§3·§5)
## 코드 _draw(기존 ColorRect 플레이스홀더 스타일과 일관). 소유 유닛(Node2D)의 자식으로 붙어 함께 움직인다.
## 비율로 녹↔적 lerp, 전투불능(쓰러짐/상실)이면 회색. 항상 표시(만피 숨김 안 함 — 사용자 결정).
class_name HpBar
extends Node2D

const BAR_W: float = 28.0
const BAR_H: float = 4.0
## 유닛 중심 기준 위쪽 오프셋 px(머리 위).
const Y_OFFSET: float = -20.0

## 0~1 채움 비율(hp/max).
var ratio: float = 1.0
## 전투불능(회색) 여부.
var incapacitated: bool = false

func set_ratio(r: float) -> void:
	ratio = clampf(r, 0.0, 1.0)
	queue_redraw()

func set_incapacitated(v: bool) -> void:
	if incapacitated != v:
		incapacitated = v
		queue_redraw()

## 채움 폭 px(순수 — 헤드리스 검증용).
func fill_width() -> float:
	return BAR_W * ratio

## 채움 색: 전투불능=회색, 아니면 비율로 적(0)↔녹(1) lerp.
func fill_color() -> Color:
	if incapacitated:
		return Color(0.5, 0.5, 0.5)
	return Color(0.85, 0.2, 0.2).lerp(Color(0.3, 0.85, 0.3), ratio)

func _draw() -> void:
	var origin := Vector2(-BAR_W * 0.5, Y_OFFSET)
	# 배경(어두운 트랙).
	draw_rect(Rect2(origin, Vector2(BAR_W, BAR_H)), Color(0.1, 0.1, 0.1, 0.8))
	# 채움.
	draw_rect(Rect2(origin, Vector2(fill_width(), BAR_H)), fill_color())

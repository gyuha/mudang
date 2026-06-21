## 월드 고정 배경 그리드(M0 관측용 플레이스홀더). ([docs/06]§3)
## 무녀+카메라가 빈 월드에서 정지처럼 보이는 문제 해소 — 이동을 시각적으로 확인하기 위한 정적 기준.
## 아트 배경이 들어오면 교체/삭제. RunScene의 첫 자식으로 붙여 뒤에 깔린다(카메라 비종속 = 월드 고정).
class_name BgGrid
extends Node2D

const CELL: int = 64
const EXTENT: int = 2000

func _draw() -> void:
	var col := Color(0.25, 0.25, 0.30, 0.6)
	var n := -EXTENT
	while n <= EXTENT:
		draw_line(Vector2(n, -EXTENT), Vector2(n, EXTENT), col)
		draw_line(Vector2(-EXTENT, n), Vector2(EXTENT, n), col)
		n += CELL

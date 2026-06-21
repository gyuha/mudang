## 균일 격자 공간 해시 — 적 근접 질의용(물리/Area2D 미사용). ([docs/06]§2)
## 매 틱 클리어+재삽입으로 재구축. id는 EnemySystem 풀 슬롯 인덱스.
## bench_500.gd의 격자 질의 방식을 정식 클래스로 끌어올린 것.
class_name SpatialHash
extends RefCounted

## 셀 크기 px ([docs/06]§2: ~64)
const CELL_SIZE: float = 64.0

## Vector2i(cell) -> PackedInt32Array(id들)
var _grid: Dictionary = {}
## id -> 위치(질의 시 반경 정밀 판정용)
var _positions: Dictionary = {}

## 전체 비우기(매 틱 재구축 시작).
func clear() -> void:
	_grid.clear()
	_positions.clear()

## id를 위치 pos로 삽입.
func insert(id: int, pos: Vector2) -> void:
	_positions[id] = pos
	var cell := _cell_of(pos)
	if not _grid.has(cell):
		_grid[cell] = PackedInt32Array()
	_grid[cell].append(id)

## center 반경 r 안의 id들. 경계는 포함(<=).
func query_circle(center: Vector2, r: float) -> PackedInt32Array:
	var out := PackedInt32Array()
	var span := int(ceil(r / CELL_SIZE))
	var base := _cell_of(center)
	var r2 := r * r
	for dx in range(-span, span + 1):
		for dy in range(-span, span + 1):
			var cell := Vector2i(base.x + dx, base.y + dy)
			if not _grid.has(cell):
				continue
			for id in _grid[cell]:
				if center.distance_squared_to(_positions[id]) <= r2:
					out.append(id)
	return out

func _cell_of(pos: Vector2) -> Vector2i:
	return Vector2i(floori(pos.x / CELL_SIZE), floori(pos.y / CELL_SIZE))

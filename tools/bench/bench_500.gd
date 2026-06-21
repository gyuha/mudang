## 일회용 성능 스파이크 — 본 게임 코드 아님(검증 후 보존만). ([docs/06]§1·§2, D19, [docs/07] M0)
## 목적: "더미 500개 = MultiMesh 1드로우콜 + 균일격자 spatial hash 이동 = PC 60fps" 렌더 접근법을
## 재미 검증 전에 싸게 확인. 게임 메인 플로우에 절대 연결하지 않는다.
## 실행: tools/bench/bench_500.tscn을 Godot에서 직접 열고 재생(F6).
extends Node2D

const AGENT_COUNT: int = 500
## spatial hash 셀 크기 px ([docs/06]§2: ~64)
const CELL_SIZE: float = 64.0
const AGENT_SPEED: float = 70.0
## 더미 사각형 한 변 px
const AGENT_SIZE: float = 8.0
## 분산 배치 영역 반경 px
const SPAWN_RADIUS: float = 600.0

var _positions: PackedVector2Array = PackedVector2Array()
var _target: Vector2 = Vector2.ZERO
var _mm: MultiMesh
var _grid: Dictionary = {}          # Vector2i(cell) -> PackedInt32Array(agent indices)
var _fps_label: Label

func _ready() -> void:
	_target = get_viewport_rect().size * 0.5

	# --- MultiMesh 1드로우콜 렌더 셋업 ---
	var quad := QuadMesh.new()
	quad.size = Vector2(AGENT_SIZE, AGENT_SIZE)

	_mm = MultiMesh.new()
	_mm.transform_format = MultiMesh.TRANSFORM_2D
	_mm.mesh = quad
	_mm.instance_count = AGENT_COUNT

	var mmi := MultiMeshInstance2D.new()
	mmi.multimesh = _mm
	# NOTE: MultiMeshInstance2D는 텍스처 없이도 QuadMesh를 흰색으로 그린다. in-editor에서 확인.
	add_child(mmi)

	# --- 더미 초기 분산 배치 ---
	_positions.resize(AGENT_COUNT)
	for i in AGENT_COUNT:
		var ang := randf() * TAU
		var dist := sqrt(randf()) * SPAWN_RADIUS
		_positions[i] = _target + Vector2(cos(ang), sin(ang)) * dist
		_mm.set_instance_transform_2d(i, Transform2D(0.0, _positions[i]))

	# --- FPS 라벨(화면 고정) ---
	var ui := CanvasLayer.new()
	add_child(ui)
	_fps_label = Label.new()
	_fps_label.position = Vector2(8, 8)
	ui.add_child(_fps_label)

func _process(delta: float) -> void:
	_rebuild_grid()
	# 균일격자 재구축은 매 프레임(500개면 충분히 쌈, [docs/06]§2).
	# 이동: 타겟 방향으로 직진(spatial hash는 근접질의 경로를 실증하기 위해 매 프레임 질의).
	for i in AGENT_COUNT:
		var pos := _positions[i]
		# 근접 질의를 실제로 한 번 돌려 spatial hash 비용을 측정에 포함시킨다(결과는 이동에 미사용 — 스파이크).
		_query_circle(pos, CELL_SIZE)
		var to_target := _target - pos
		if to_target.length() > 1.0:
			pos += to_target.normalized() * AGENT_SPEED * delta
		_positions[i] = pos
		_mm.set_instance_transform_2d(i, Transform2D(0.0, pos))

	_fps_label.text = "FPS: %d\nagents: %d (1 MultiMesh draw call)\ncell: %d px" % [
		Engine.get_frames_per_second(), AGENT_COUNT, int(CELL_SIZE)
	]

## 격자 재구축: 클리어 후 전 더미 재삽입.
func _rebuild_grid() -> void:
	_grid.clear()
	for i in AGENT_COUNT:
		var cell := _cell_of(_positions[i])
		if not _grid.has(cell):
			_grid[cell] = PackedInt32Array()
		_grid[cell].append(i)

## center 반경 r 안의 더미 인덱스들(균일격자 근접 질의).
func _query_circle(center: Vector2, r: float) -> PackedInt32Array:
	var out := PackedInt32Array()
	var span := int(ceil(r / CELL_SIZE))
	var base := _cell_of(center)
	var r2 := r * r
	for dx in range(-span, span + 1):
		for dy in range(-span, span + 1):
			var cell := Vector2i(base.x + dx, base.y + dy)
			if not _grid.has(cell):
				continue
			for idx in _grid[cell]:
				if center.distance_squared_to(_positions[idx]) <= r2:
					out.append(idx)
	return out

func _cell_of(pos: Vector2) -> Vector2i:
	return Vector2i(floori(pos.x / CELL_SIZE), floori(pos.y / CELL_SIZE))

## 런 1회의 월드 루트. ([docs/06]§3 씬 트리)
## M0: Camera2D(무녀 추적) + Mudang + 입력 디버그 라벨.
## M1 추가: EnemySystem(단순 풀링 백엔드) + 스폰 포인트(우물 상시 + 크랙 시간차 개방) +
##         잡귀 추격(최근접 아군 타겟=무녀) + 무녀 접촉 피해. ([docs/04] D24, [docs/06]§2, [docs/00] D6-a)
## 노드 트리는 코드로 구성한다(손작성 .tscn 회피). 데이터 주도 배치(StageDef/WaveDirector)는 M6 Non-goal.
class_name RunScene
extends Node2D

## 잡귀 데이터 ([docs/09]§2 mob_low).
const MOB_LOW_PATH: String = "res://data/enemies/mob_low.tres"
## 스폰 간격 s — 활성 포인트당 1마리씩.
const SPAWN_INTERVAL: float = 0.4
## 스폰 포인트 등장 텔레그래프(솟는 연출) 시간 s.
const EMERGE_TELEGRAPH: float = 0.35

var _mudang: Mudang
var _camera: Camera2D
var _debug_label: Label
var _enemies: EnemySystem
var _mob_low: EnemyDef

## 스폰 포인트: {pos, kind("well"|"crack"), open_at(개방 시각 s), opened(bool)}
var _spawn_points: Array[Dictionary] = []
var _run_time: float = 0.0
var _spawn_accum: float = 0.0

func _ready() -> void:
	# 월드 고정 배경 그리드(첫 자식 = 뒤에 깔림). 이동 관측용 정적 기준 — 아트 배경 들어오면 교체.
	add_child(BgGrid.new())

	_mudang = Mudang.new()
	add_child(_mudang)

	# 무녀를 추적하는 카메라. 무녀 자식으로 붙여 위치를 따라가게 한다.
	_camera = Camera2D.new()
	_camera.enabled = true
	_mudang.add_child(_camera)

	# 적 시스템. 아군 타겟 목록에 무녀를 등록(M2 동료 확장 가능).
	_enemies = EnemySystem.new()
	add_child(_enemies)
	_enemies.ally_targets = [_mudang]

	_mob_low = load(MOB_LOW_PATH) as EnemyDef

	_setup_spawn_points()

	# 입력 디버그 라벨(M0). CanvasLayer에 올려 카메라 이동과 무관하게 화면 고정.
	var ui_layer := CanvasLayer.new()
	add_child(ui_layer)
	_debug_label = Label.new()
	_debug_label.position = Vector2(8, 8)
	ui_layer.add_child(_debug_label)

## 스폰 포인트 하드코딩: 우물 2개(상시) + 크랙 3개(시간차 개방). ([docs/04] D24)
## 플레이스홀더 표시 — 우물=원, 크랙=사각. 데이터 주도 배치는 M6 Non-goal.
func _setup_spawn_points() -> void:
	# 우물: 상시 활성(open_at=0).
	_add_spawn_point(Vector2(-400, -250), "well", 0.0)
	_add_spawn_point(Vector2(420, 300), "well", 0.0)
	# 크랙: 시간이 지나면 추가 개방(런 진행 = 더 많은 크랙 = 스폰↑).
	_add_spawn_point(Vector2(350, -350), "crack", 4.0)
	_add_spawn_point(Vector2(-450, 320), "crack", 9.0)
	_add_spawn_point(Vector2(0, 450), "crack", 15.0)

func _add_spawn_point(pos: Vector2, kind: String, open_at: float) -> void:
	_spawn_points.append({"pos": pos, "kind": kind, "open_at": open_at, "opened": false})
	# 플레이스홀더 마커: 우물=원(노란), 크랙=사각(주황). 솟는 위치 가시화.
	var marker := _SpawnMarker.new()
	marker.position = pos
	marker.kind = kind
	add_child(marker)

func _physics_process(delta: float) -> void:
	_run_time += delta

	# 크랙 시간차 개방.
	for sp in _spawn_points:
		if not sp["opened"] and _run_time >= sp["open_at"]:
			sp["opened"] = true

	# 활성 포인트에서 상한까지 스폰(짧은 간격). 텔레그래프는 등장 시각 지연으로 근사.
	_spawn_accum += delta
	while _spawn_accum >= SPAWN_INTERVAL:
		_spawn_accum -= SPAWN_INTERVAL
		_spawn_from_active_points()

	# 적 AI 이동 + 격자 재구축.
	_enemies.tick(delta)

	# 무녀 접촉 피해: 무녀 주변 적 질의 → 접촉 적 수 × contact_damage/s. ([docs/00] D6-a)
	var contacts := _enemies.query_circle(_mudang.global_position, EnemySystem.CONTACT_RADIUS)
	if contacts.size() > 0:
		_mudang.take_contact_damage(_mob_low.contact_damage * contacts.size() * delta)

func _spawn_from_active_points() -> void:
	for sp in _spawn_points:
		if not sp["opened"]:
			continue
		if _enemies.active_count() >= EnemySystem.CAP:
			return
		_enemies.spawn(_mob_low, sp["pos"])

func _process(_delta: float) -> void:
	_debug_label.text = "무녀 HP: %d/%d\n적 수: %d / %d\n런 시간: %.1fs\n무녀 pos: %s\nmove_vector: %s" % [
		int(_mudang.hp), int(Mudang.MAX_HP),
		_enemies.active_count(), EnemySystem.CAP,
		_run_time,
		_mudang.global_position.round(),
		InputAdapter.move_vector,
	]

## 스폰 포인트 플레이스홀더 마커(솟는 위치 가시화). 우물=원, 크랙=사각.
class _SpawnMarker extends Node2D:
	var kind: String = "well"
	func _draw() -> void:
		if kind == "well":
			draw_circle(Vector2.ZERO, 20.0, Color(0.9, 0.85, 0.3, 0.7))
		else:
			draw_rect(Rect2(-18, -14, 36, 28), Color(0.9, 0.5, 0.2, 0.7))

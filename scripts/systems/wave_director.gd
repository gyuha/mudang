## 웨이브 디렉터(M6) — StageDef 데이터 주도 하이브리드 스폰. ([docs/04]§2, [docs/09]§5, D18)
## 타임라인 채널(고정 이벤트, 정시 1회 발동) + 예산 채널(budget_per_sec 누적 → 활성 풀 가중추첨 소비).
## 스폰 위치는 월드 배치 스폰 포인트(D24). RunScene이 tick(dt, run_time)으로 구동(결정성).
class_name WaveDirector
extends Node

## 폭주 방지: 한 틱 예산 스폰 상한.
const MAX_SPAWNS_PER_TICK: int = 200

var stage: StageDef
var enemies: EnemySystem
var spawn_points: Array[Vector2] = []

var _budget: float = 0.0
## 타임라인 이벤트별 발동 여부(인덱스 대응).
var _fired: Array = []
## 스폰 포인트 라운드로빈 커서.
var _point_cursor: int = 0

## 지금까지 발동한 타임라인 이벤트 수(검증/디버그용).
func fired_count() -> int:
	var n := 0
	for f in _fired:
		if f:
			n += 1
	return n

func setup(s: StageDef, e: EnemySystem, points: Array[Vector2]) -> void:
	stage = s
	enemies = e
	spawn_points = points
	_fired.resize(stage.timeline.size())
	_fired.fill(false)

## 한 스텝: 타임라인 정시 발동 + 예산 스폰.
func tick(dt: float, run_time: float) -> void:
	if stage == null or enemies == null or spawn_points.is_empty():
		return
	# 타임라인 채널: time 도달 + 미발동 → 1회 발동.
	for i in stage.timeline.size():
		if _fired[i]:
			continue
		var ev: TimelineEvent = stage.timeline[i]
		if run_time >= ev.time:
			_fired[i] = true
			_fire_event(ev)
	# 예산 채널: 누적분으로 활성 풀에서 가중추첨 스폰.
	_budget += stage.budget_per_sec(run_time) * dt
	var n := 0
	while n < MAX_SPAWNS_PER_TICK:
		n += 1
		var entry := _pick_pool(run_time)
		if entry == null:
			break
		var cost: float = float(entry.enemy.spawn_cost)
		if _budget < cost or _at_cap():
			break
		_budget -= cost
		enemies.spawn(entry.enemy, _next_point())

## 현재 활성 적 상한 도달?(스테이지 max_active와 백엔드 CAP 중 작은 값)
func _at_cap() -> bool:
	return enemies.active_count() >= min(stage.max_active_enemies, EnemySystem.CAP)

## SPAWN_GROUP/MINIBOSS/RUSH: enemy×count 즉시 스폰(상한 클램프).
func _fire_event(ev: TimelineEvent) -> void:
	if ev.enemy == null:
		return
	for _i in ev.count:
		if _at_cap():
			return
		enemies.spawn(ev.enemy, _next_point())

## 활성 spawn_pool 항목 중 가중 추첨. 활성 없으면 null.
func _pick_pool(t: float) -> SpawnPoolEntry:
	var total := 0.0
	for sp in stage.spawn_pool:
		if sp.is_active(t):
			total += sp.weight
	if total <= 0.0:
		return null
	var r := randf() * total
	for sp in stage.spawn_pool:
		if not sp.is_active(t):
			continue
		r -= sp.weight
		if r <= 0.0:
			return sp
	return null

## 스폰 포인트 라운드로빈.
func _next_point() -> Vector2:
	var p := spawn_points[_point_cursor % spawn_points.size()]
	_point_cursor += 1
	return p

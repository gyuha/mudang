## 적 시스템 — 단순 풀링 백엔드(~150 상한). ([docs/06]§1·§2, [docs/11]§1, [docs/04])
## 적은 노드가 아니라 병렬 배열(SoA-lite)로 관리하고, 풀 슬롯당 ColorRect 플레이스홀더를 둔다.
## SoA+MultiMesh 스케일업(500+)은 M-S Non-goal — ~150에선 슬롯당 ColorRect로 충분.
## 죽으면 swap-remove로 빈 슬롯 회수(할당 0). 근접 질의는 SpatialHash(물리 미사용).
## 공개 API([docs/11]§1): spawn / query_circle / position_of / apply_damage.
class_name EnemySystem
extends Node2D

## 동시 적 상한 — 단순 백엔드 한계(M-S에서 MultiMesh로 500 확장). ([docs/06]§5는 500이나 M1은 ~150)
const CAP: int = 150
## 플레이스홀더 한 변 px
const PLACEHOLDER_SIZE: float = 12.0
## 접촉 판정 반경 px — 적 반(半) + 아군 반 근사. ([docs/04]§1 접촉피해=초당)
const CONTACT_RADIUS: float = 18.0

## 병렬 배열(풀). 유효 범위는 [0, _count).
var _pos: PackedVector2Array = PackedVector2Array()
var _hp: PackedFloat32Array = PackedFloat32Array()
var _def: Array[EnemyDef] = []
var _rects: Array[ColorRect] = []
var _count: int = 0

## 적이 향하는 아군 타겟 노드 목록(M1=무녀만, M2 동료 확장 가능). 각 원소는 global_position을 가진 Node2D.
var ally_targets: Array[Node2D] = []

var _hash: SpatialHash = SpatialHash.new()

## 현재 활성 적 수.
func active_count() -> int:
	return _count

## --- 공개 API ([docs/11]§1) ---

## 적 1마리 스폰. 상한 도달 시 무시(클램프). 풀 슬롯 인덱스를 반환(-1=상한).
func spawn(def: EnemyDef, pos: Vector2) -> int:
	if _count >= CAP:
		return -1
	var idx := _count
	if idx < _pos.size():
		# 회수된 슬롯 재사용(swap-remove로 빈 자리). 배열 길이는 최고치 유지.
		_pos[idx] = pos
		_hp[idx] = def.max_hp
		_def[idx] = def
		_rects[idx].visible = true
		_rects[idx].position = pos - Vector2(PLACEHOLDER_SIZE, PLACEHOLDER_SIZE) * 0.5
	else:
		_pos.append(pos)
		_hp.append(def.max_hp)
		_def.append(def)
		var rect := ColorRect.new()
		rect.color = Color(0.55, 0.75, 0.95)
		rect.size = Vector2(PLACEHOLDER_SIZE, PLACEHOLDER_SIZE)
		rect.position = pos - rect.size * 0.5
		add_child(rect)
		_rects.append(rect)
	_count += 1
	return idx

## center 반경 r 안의 적 슬롯 인덱스들. (SpatialHash 위임, 물리 미사용)
func query_circle(center: Vector2, r: float) -> PackedInt32Array:
	return _hash.query_circle(center, r)

## 슬롯 idx의 현재 위치.
func position_of(idx: int) -> Vector2:
	return _pos[idx]

## 슬롯 idx에 피해. HP<=0 시 처치+슬롯 회수(swap-remove).
func apply_damage(idx: int, amount: float) -> void:
	if idx < 0 or idx >= _count:
		return
	_hp[idx] -= amount
	if _hp[idx] <= 0.0:
		_kill(idx)

## --- 내부 ---

## swap-remove: 마지막 활성 슬롯을 idx로 당겨오고 _count 감소. 빈 ColorRect는 숨겨 재사용 대기.
func _kill(idx: int) -> void:
	var last := _count - 1
	# 죽는 적의 ColorRect는 풀 꼬리로 보내 숨김(다음 spawn에서 재사용).
	var dead_rect := _rects[idx]
	dead_rect.visible = false
	if idx != last:
		_pos[idx] = _pos[last]
		_hp[idx] = _hp[last]
		_def[idx] = _def[last]
		_rects[idx] = _rects[last]
		_rects[last] = dead_rect
	_count -= 1

## 매 틱: SpatialHash 재구축 + AI 이동(최근접 아군 타겟 직진) + 렌더 위치 갱신.
func tick(dt: float) -> void:
	_hash.clear()
	for i in _count:
		_hash.insert(i, _pos[i])

	if ally_targets.is_empty():
		return
	for i in _count:
		var target := _nearest_target(_pos[i])
		var to := target - _pos[i]
		if to.length() > 0.5:
			_pos[i] += to.normalized() * _def[i].move_speed * dt
		_rects[i].position = _pos[i] - Vector2(PLACEHOLDER_SIZE, PLACEHOLDER_SIZE) * 0.5

## 가장 가까운 아군 타겟의 위치(M1=무녀만, M2 확장 대비 목록 순회).
func _nearest_target(from: Vector2) -> Vector2:
	var best := ally_targets[0].global_position
	var best_d := from.distance_squared_to(best)
	for t in ally_targets:
		var d := from.distance_squared_to(t.global_position)
		if d < best_d:
			best_d = d
			best = t.global_position
	return best

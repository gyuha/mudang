## 적 시스템 — SoA + MultiMesh 백엔드(500+ 스케일업, M-S). ([docs/06]§1·§2·§5, [docs/11]§1, [docs/04], [docs/07] M-S)
## 적은 노드가 아니라 병렬 배열(SoA)로 관리하고, 렌더는 EnemyDef.id(텍스처)별 MultiMeshInstance2D 1개로 일괄 배치(드로우콜 = 적종 수).
## 매 tick SoA 위치를 버킷별 인스턴스 transform으로 일괄 기록(_render). 공개 API 불변 — 게임플레이 코드 무수정.
## 죽으면 swap-remove로 빈 슬롯 회수(할당 0). 근접 질의는 SpatialHash(물리 미사용).
## 공개 API([docs/11]§1): spawn / query_circle / position_of / apply_damage / tick.
class_name EnemySystem
extends Node2D

## 동시 적 상한 — MultiMesh 백엔드로 500+ 지원. ([docs/06]§5 PC 500)
const CAP: int = 512
## 접촉 판정 반경 px — 적 반(半) + 아군 반 근사. ([docs/04]§1 접촉피해=초당)
const CONTACT_RADIUS: float = 18.0

## 병렬 배열(풀). 유효 범위는 [0, _count).
var _pos: PackedVector2Array = PackedVector2Array()
var _hp: PackedFloat32Array = PackedFloat32Array()
var _def: Array[EnemyDef] = []
## 렌더 버킷: EnemyDef.id → MultiMeshInstance2D(QuadMesh=sprite_size, 텍스처=id.png). 적종당 1드로우콜.
var _buckets: Dictionary = {}
## 넉백 경직 잔여 시간 s(>0이면 이번 틱 이동 스킵). ([docs/01]§3 0.15s 경직)
var _stun: PackedFloat32Array = PackedFloat32Array()
var _count: int = 0

## 적이 향하는 아군 타겟 노드 목록(M1=무녀만, M2 동료 확장 가능). 각 원소는 global_position을 가진 Node2D.
var ally_targets: Array[Node2D] = []

## --- 오라 감속(M3, RunScene이 매 틱 무녀 기준으로 주입). ([docs/01]§2) ---
## aura_radius<=0 이면 비활성. 반경 내 적 이동속도 ×aura_slow.
var aura_center: Vector2 = Vector2.ZERO
var aura_radius: float = 0.0
var aura_slow: float = 1.0

## 적 처치 시 드랍 훅(M3). 시그니처: func(pos: Vector2, drop: DropTable). 미설정이면 무시.
var on_kill: Callable = Callable()
## 적 처치 시 정의 훅(kill_boss 목표용). 시그니처: func(def: EnemyDef). 드랍 유무와 무관하게 매 처치 호출.
var on_killed: Callable = Callable()

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
		_stun[idx] = 0.0
	else:
		_pos.append(pos)
		_hp.append(def.max_hp)
		_def.append(def)
		_stun.append(0.0)
	# 이 적종 텍스처 버킷 보장(렌더는 _render가 매 tick 일괄 기록).
	_ensure_bucket(def)
	_count += 1
	return idx

## EnemyDef.id별 MultiMeshInstance2D 버킷 보장(최초 1회 생성). QuadMesh=sprite_size, 텍스처=id.png.
func _ensure_bucket(def: EnemyDef) -> void:
	if _buckets.has(def.id):
		return
	var quad := QuadMesh.new()
	quad.size = Vector2(def.sprite_size, def.sprite_size)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_2D
	mm.mesh = quad
	mm.instance_count = 0
	var mmi := MultiMeshInstance2D.new()
	mmi.multimesh = mm
	mmi.texture = load("res://assets/sprites/%s.png" % def.id) as Texture2D
	add_child(mmi)
	_buckets[def.id] = mmi

## SoA 활성 위치를 적종(텍스처)별 MultiMesh 인스턴스 transform으로 일괄 기록. 매 tick 호출.
func _render() -> void:
	# 적종별 활성 위치 수집.
	var groups: Dictionary = {}  # StringName -> PackedVector2Array
	for i in _count:
		var id: StringName = _def[i].id
		if not groups.has(id):
			groups[id] = PackedVector2Array()
		groups[id].append(_pos[i])
	# 각 버킷에 기록(이번 tick에 없는 버킷은 instance_count=0).
	for id in _buckets:
		var mm: MultiMesh = _buckets[id].multimesh
		var ps: PackedVector2Array = groups.get(id, PackedVector2Array())
		mm.instance_count = ps.size()
		for j in ps.size():
			mm.set_instance_transform_2d(j, Transform2D(0.0, ps[j]))

## center 반경 r 내 적을 바깥으로 변위(×(1-resist)) + 0.15s 경직. 데미지 없음. ([docs/01]§3)
## _hash는 직전 tick에서 구축됨(RunScene은 tick 후 호출). 호출자가 쿨다운/사거리 게이트.
func apply_knockback(center: Vector2, radius: float, force: float) -> void:
	for idx in _hash.query_circle(center, radius):
		var off := _pos[idx] - center
		var dir := off.normalized() if off.length() > 0.01 else Vector2.RIGHT
		var resist: float = _def[idx].knockback_resist
		_pos[idx] += dir * force * (1.0 - resist)
		_stun[idx] = 0.15

## center 반경 r 안의 적 슬롯 인덱스들. (SpatialHash 위임, 물리 미사용)
func query_circle(center: Vector2, r: float) -> PackedInt32Array:
	return _hash.query_circle(center, r)

## 슬롯 idx의 현재 위치.
func position_of(idx: int) -> Vector2:
	return _pos[idx]

## 슬롯 idx의 적 정의(타게팅 우선순위 ELITE 판정용, M2). ([docs/02]§2)
func def_of(idx: int) -> EnemyDef:
	return _def[idx]

## 슬롯 idx에 피해. HP<=0 시 처치+슬롯 회수(swap-remove).
func apply_damage(idx: int, amount: float) -> void:
	if idx < 0 or idx >= _count:
		return
	_hp[idx] -= amount
	if _hp[idx] <= 0.0:
		_kill(idx)

## --- 내부 ---

## swap-remove: 마지막 활성 슬롯을 idx로 당겨오고 _count 감소. 렌더는 _render가 _count 기준으로 재기록.
func _kill(idx: int) -> void:
	# 드랍 훅(M3): 죽은 위치+드랍테이블을 SoulfireSystem 등에 전달. ([docs/03]§1)
	if on_kill.is_valid() and _def[idx].drop != null:
		on_kill.call(_pos[idx], _def[idx].drop)
	# 처치 정의 훅(kill_boss 목표): 죽은 적의 def를 전달(보스 id 매칭용).
	if on_killed.is_valid():
		on_killed.call(_def[idx])
	var last := _count - 1
	if idx != last:
		_pos[idx] = _pos[last]
		_hp[idx] = _hp[last]
		_def[idx] = _def[last]
		_stun[idx] = _stun[last]
	_count -= 1

## 매 틱: SpatialHash 재구축 + AI 이동(최근접 아군 타겟 직진) + MultiMesh 렌더 일괄 갱신.
func tick(dt: float) -> void:
	_hash.clear()
	for i in _count:
		_hash.insert(i, _pos[i])

	# 이동(아군 타겟 있을 때만). 렌더는 타겟 유무와 무관하게 매 틱.
	if not ally_targets.is_empty():
		for i in _count:
			# 넉백 경직 중이면 이동 스킵. ([docs/01]§3)
			if _stun[i] > 0.0:
				_stun[i] = max(0.0, _stun[i] - dt)
				continue
			var target := _nearest_target(_pos[i])
			var to := target - _pos[i]
			# 오라 감속: 무녀 반경 내면 이동속도 ×aura_slow. (매 적 Area2D 금지 — 거리검사) ([docs/01]§2)
			var speed: float = _def[i].move_speed
			if aura_radius > 0.0 and _pos[i].distance_to(aura_center) <= aura_radius:
				speed *= aura_slow
			if to.length() > 0.5:
				_pos[i] += to.normalized() * speed * dt
	_render()

## 적이 향할 아군 타겟 위치. M2: 도발 오버라이드 → 기본 최근접 동료. ([docs/02]§2.1, [docs/04]§1)
## from이 어떤 탱(get_taunt_radius()>0)의 도발 반경 안이면 그 탱을 타겟(없으면 최근접 동료).
func _nearest_target(from: Vector2) -> Vector2:
	# 도발 오버라이드: 도발 반경 내 가장 가까운 탱이 우선.
	var taunt_best := Vector2.ZERO
	var taunt_d := INF
	for t in ally_targets:
		if t.has_method(&"get_taunt_radius"):
			var tr: float = t.get_taunt_radius()
			if tr > 0.0:
				var tp: Vector2 = t.global_position
				var d := from.distance_squared_to(tp)
				if d <= tr * tr and d < taunt_d:
					taunt_d = d
					taunt_best = tp
	if taunt_d < INF:
		return taunt_best
	# 기본: 최근접 아군 타겟.
	var best := ally_targets[0].global_position
	var best_d := from.distance_squared_to(best)
	for t in ally_targets:
		var d := from.distance_squared_to(t.global_position)
		if d < best_d:
			best_d = d
			best = t.global_position
	return best

## 동료 — 자율 AI 전투원(플레이스홀더 표현). ([docs/02], 수치 [docs/09]§1, D9·D20·D25)
## 공통 FSM(ACQUIRE→ENGAGE→REPOSITION) + role_id 분기. RALLY/DOWNED/LOST는 M3/M4에서 배선(enum만 선언).
## 결정은 0.15s 틱, 이동은 매 프레임. 근접 질의는 EnemySystem(SpatialHash) — 전체 적 스캔 금지([docs/02]§3).
class_name Companion
extends Node2D

## 결정 틱 주기 s ([docs/02]§1: 0.1~0.2s)
const DECISION_TICK: float = 0.15
## 적 탐지 반경 px(해시 질의 — 아레나 내 획득). 전체 스캔 아님.
const SENSE_RADIUS: float = 700.0
## 동료끼리 겹침 방지 분리 반경 px
const SEPARATION_RADIUS: float = 28.0
## 분리 스티어링 세기 px/s
const SEPARATION_FORCE: float = 80.0
## leash 초과 시 무녀 방향 가중(0~1, 모여라보다 약하게)
const LEASH_PULL: float = 0.6
## 모여라(RALLY) 중 무녀 방향 가중(leash보다 강하게 — 교전하며 수렴). ([docs/01]§5)
const RALLY_BIAS: float = 0.9
## 쓰러짐 제한시간 s — 초과 시 상실(LOST). 넋달래기 업그레이드는 M5. ([docs/02]§4)
const DOWNED_TIMER: float = 8.0
## 부활 후 HP 비율(최대치 대비). ([docs/02]§5)
const REVIVE_HP_RATIO: float = 0.4
## 채널 이탈 시 부활 게이지 감쇠 속도 배수(천천히 감쇠). ([docs/02]§5)
const REVIVE_DECAY_RATE: float = 0.5
## 플레이스홀더 한 변 px(스프라이트 누락 시 폴백)
const PLACEHOLDER_SIZE: float = 22.0
## 표시 스프라이트 한 변 px(원본 1024 텍스처 축소)
const SPRITE_SIZE: float = 64.0

## 타게팅 우선순위 enum ([docs/02]§2)
enum Priority { NEAREST, DENSEST, ELITE, LOWHP_ALLY }
## 공통 상태. RALLY/DOWNED/LOST는 M2 미사용(M3/M4 배선).
enum State { ACQUIRE, ENGAGE, REPOSITION, RALLY, DOWNED, LOST }

## 동료 정의(스탯+역할). RunScene/체크 씬이 주입.
var def: CompanionDef
## 적 시스템 참조(타게팅/피해).
var enemies: EnemySystem
## 무녀 참조(leash/카이팅 후퇴 기준).
var mudang: Node2D
## 같은 편 동료 목록(자신 포함 — 힐 대상/분리용). RunScene이 주입.
var allies: Array = []

var hp: float = 0.0
## 전달받은 혼불 EXP(현재 레벨 내 누적). ([docs/03]§3)
var companion_exp: float = 0.0
## 동료 레벨(시작 1).
var companion_level: int = 1
## 강화 대기 수(레벨업 적립, 상한 3 — 머리 위 아이콘/적용 UI는 M5-UI Non-goal). ([docs/03]§3)
var pending_upgrades: int = 0
## pending 상한(초과 시 자동 최선픽은 M5-UI).
const PENDING_CAP: int = 3
var _state: int = State.ACQUIRE
var _decision_accum: float = 0.0
var _attack_accum: float = 0.0
## 모여라 잔여 시간 s(>0이면 무녀로 수렴). ([docs/01]§5)
var _rally_remaining: float = 0.0
## 쓰러짐 잔여 시간 s(DOWNED 중 감소, 0이면 LOST). ([docs/02]§4)
var _downed_remaining: float = 0.0
## 부활 채널 게이지 s(revive_channel_time 도달 시 부활). ([docs/02]§5)
var _revive_gauge: float = 0.0
## 현재 타겟 적 슬롯(-1=없음).
var _target_idx: int = -1
var _rect: ColorRect
## 머리 위 HP 바(HUD). RunScene이 매 프레임 refresh_hp_bar()로 갱신.
var hp_bar: HpBar

func _ready() -> void:
	if def != null:
		hp = def.max_hp
	# 생성 스프라이트(투명, id별). 없으면 역할색 ColorRect 폴백(eco: 에셋 누락 방어).
	var tex: Texture2D = null
	if def != null:
		tex = load("res://assets/sprites/%s.png" % def.id) as Texture2D
	if tex != null:
		var spr := Sprite2D.new()
		spr.texture = tex
		spr.scale = Vector2.ONE * (SPRITE_SIZE / tex.get_width())
		add_child(spr)
	else:
		_rect = ColorRect.new()
		_rect.color = _role_color()
		_rect.size = Vector2(PLACEHOLDER_SIZE, PLACEHOLDER_SIZE)
		_rect.position = -_rect.size * 0.5
		add_child(_rect)

	# 머리 위 HP 바(HUD 슬라이스).
	hp_bar = HpBar.new()
	add_child(hp_bar)

## HP 바 갱신(RunScene가 매 프레임 호출). 쓰러짐/상실이면 회색.
func refresh_hp_bar() -> void:
	if def == null:
		return
	hp_bar.set_ratio(hp / def.max_hp)
	hp_bar.set_incapacitated(is_incapacitated())

## 역할별 플레이스홀더 색(아군 식별 — 외곽 발광은 M8). 적(청록 계열)과 구분.
func _role_color() -> Color:
	match _role():
		&"tank": return Color(0.30, 0.55, 0.95)    # 청
		&"ranged": return Color(0.40, 0.85, 0.45)   # 녹
		&"healer": return Color(0.95, 0.90, 0.55)   # 금
		_: return Color(0.8, 0.8, 0.8)

func _role() -> StringName:
	return def.role_id if def != null else &""

## 도발 반경(EnemySystem이 적 타게팅 오버라이드에 사용). 비탱이면 0.
func get_taunt_radius() -> float:
	return def.taunt_radius if def != null else 0.0

## 접촉 피해 수용(초당값 × dt를 호출자가 전달). 받피 감소 적용. M4: HP 0 → 쓰러짐(즉사 아님), DOWNED/LOST 중 무적.
func take_contact_damage(amount: float) -> void:
	if def == null or is_incapacitated():
		return
	hp = max(0.0, hp - amount * (1.0 - def.damage_reduction))
	if hp <= 0.0:
		_enter_downed()

## 전투 불가(쓰러짐/상실) 상태인가 — 적 타게팅·접촉피해·전투에서 제외 대상.
func is_incapacitated() -> bool:
	return _state == State.DOWNED or _state == State.LOST

func is_downed() -> bool:
	return _state == State.DOWNED

func is_lost() -> bool:
	return _state == State.LOST

## HP 0 → 쓰러짐 진입(제한시간 시작). ([docs/02]§4)
func _enter_downed() -> void:
	_state = State.DOWNED
	hp = 0.0
	_downed_remaining = DOWNED_TIMER
	_revive_gauge = 0.0

## 부활 채널 1스텝(무녀가 정지·근접 시 RunScene이 호출). 충전 완료 시 부활하고 true. ([docs/02]§5)
func revive_progress(dt: float, channel_time: float) -> bool:
	if _state != State.DOWNED:
		return false
	_revive_gauge += dt
	if _revive_gauge >= channel_time:
		hp = def.max_hp * REVIVE_HP_RATIO
		_state = State.ACQUIRE
		_revive_gauge = 0.0
		_downed_remaining = 0.0
		return true
	return false

## 부활 채널 이탈 — 게이지 천천히 감쇠(다시 들어오면 재개). ([docs/02]§5)
func revive_decay(dt: float) -> void:
	if _state == State.DOWNED:
		_revive_gauge = max(0.0, _revive_gauge - dt * REVIVE_DECAY_RATE)

## 힐 수령(견습무당 → 아군). 최대 HP 초과 없음.
func heal_received(amount: float) -> void:
	if def == null:
		return
	hp = min(def.max_hp, hp + amount)

## 동료 EXP까지 필요량. ([docs/03]§3: floor(6*1.18^(n-1)))
func comp_exp_to_next(n: int) -> int:
	return int(floor(6.0 * pow(1.18, n - 1)))

## 전달받은 혼불 EXP 적립(SoulfireSystem 전달이 호출). 레벨업 시 pending++(상한 3). ([docs/03]§3)
func add_companion_exp(v: float) -> void:
	companion_exp += v
	while companion_exp >= float(comp_exp_to_next(companion_level)):
		companion_exp -= float(comp_exp_to_next(companion_level))
		companion_level += 1
		pending_upgrades = min(PENDING_CAP, pending_upgrades + 1)

## 강화 대기 여부(머리 위 아이콘 = M5-UI).
func has_pending() -> bool:
	return pending_upgrades > 0

## 현재 상태(체크/디버그용).
func state_name() -> String:
	return State.keys()[_state]

## 모여라 발동(RunScene이 쿨다운 게이트 후 호출). duration 동안 무녀로 수렴. ([docs/01]§5)
func start_rally(duration: float) -> void:
	_rally_remaining = duration

## 한 스텝 진행(RunScene/체크 씬이 매 프레임 호출 — EnemySystem.tick과 동일 패턴, 결정성 확보).
func step(dt: float) -> void:
	if def == null:
		return
	# 케어(M4): 상실은 정지, 쓰러짐은 타이머만 감소(전투/이동 없음). ([docs/02]§4)
	if _state == State.LOST:
		return
	if _state == State.DOWNED:
		_downed_remaining = max(0.0, _downed_remaining - dt)
		if _downed_remaining <= 0.0:
			_state = State.LOST
		return
	if _rally_remaining > 0.0:
		_rally_remaining = max(0.0, _rally_remaining - dt)
	_decision_accum += dt
	if _decision_accum >= DECISION_TICK:
		_decision_accum = 0.0
		_decide()
	_act(dt)

## 0.15s 결정: 비힐러는 우선순위로 타겟 획득. 힐러는 적 타겟 없음.
func _decide() -> void:
	if def.heal_per_sec > 0.0:
		_target_idx = -1
		return
	_target_idx = _pick_target()
	_state = State.ENGAGE if _target_idx >= 0 else State.ACQUIRE

## 우선순위에 따른 타겟 적 슬롯. 없으면 -1.
func _pick_target() -> int:
	if enemies == null:
		return -1
	var near := enemies.query_circle(global_position, SENSE_RADIUS)
	if near.is_empty():
		return -1
	var best := -1
	match def.target_priority:
		Priority.ELITE:
			# 최대 max_hp(정예) 우선, 동률은 최근접.
			var best_hp := -1.0
			var best_d := INF
			for idx in near:
				var ehp: float = enemies.def_of(idx).max_hp
				var d := global_position.distance_squared_to(enemies.position_of(idx))
				if ehp > best_hp or (ehp == best_hp and d < best_d):
					best_hp = ehp
					best_d = d
					best = idx
		_:
			# NEAREST / DENSEST(슬라이스 폴백) — 최근접.
			var best_d := INF
			for idx in near:
				var d := global_position.distance_squared_to(enemies.position_of(idx))
				if d < best_d:
					best_d = d
					best = idx
	return best

## 매 프레임 행동: 이동(상태별) + 공격/힐 + 분리 + leash.
func _act(dt: float) -> void:
	var vel := Vector2.ZERO
	if def.heal_per_sec > 0.0:
		vel = _healer_move()
		_heal(dt)
	else:
		_attack_accum += dt
		if _target_idx >= 0 and _target_idx < enemies.active_count():
			var tpos := enemies.position_of(_target_idx)
			var d := global_position.distance_to(tpos)
			if def.kite_min > 0.0 and d < def.kite_min:
				# 카이팅: 적이 너무 가까움 → 무녀 방향으로 후퇴하며 사격.
				_state = State.REPOSITION
				var away := (global_position - tpos)
				if mudang != null:
					away += (mudang.global_position - global_position).normalized() * 0.5
				vel = away.normalized() * def.move_speed
				_try_attack(d)
			else:
				_state = State.ENGAGE
				if d > def.attack_range:
					vel = (tpos - global_position).normalized() * def.move_speed
				_try_attack(d)
		else:
			# 타겟 없음 → 무녀 쪽으로 약하게 재집결.
			_state = State.ACQUIRE
			vel = _toward_mudang_soft()
	vel += _separation()
	vel = _apply_leash(vel)
	# 모여라: 이동을 무녀 방향으로 수렴 override(공격은 위 engage 분기에서 이미 발사 — "교전 유지"). ([docs/01]§5)
	# 원거리 적 추격을 이겨 실제로 모이도록 add가 아닌 override(RALLY_BIAS는 수렴 속도 비율).
	if _rally_remaining > 0.0 and mudang != null:
		_state = State.RALLY
		var to_m := mudang.global_position - global_position
		if to_m.length() > 4.0:
			vel = to_m.normalized() * def.move_speed * RALLY_BIAS + _separation()
		else:
			vel = _separation()
	position += vel * dt

## 쿨다운+사거리 충족 시 타겟에 즉시 피해(투사체/관통은 M8).
func _try_attack(dist_to_target: float) -> void:
	if def.attack_damage <= 0.0:
		return
	if _attack_accum >= def.attack_period and dist_to_target <= def.attack_range:
		enemies.apply_damage(_target_idx, def.attack_damage)
		_attack_accum = 0.0

## 힐러 이동: 최저HP 아군(자신 포함) 곁에 머묾. 다 차 있으면 무녀 쪽.
func _healer_move() -> Vector2:
	var target := _lowest_hp_ally(false)
	if target != null and target != self:
		var d := global_position.distance_to(target.global_position)
		if d > def.heal_radius * 0.6:
			return (target.global_position - global_position).normalized() * def.move_speed
		return Vector2.ZERO
	return _toward_mudang_soft()

## 힐 적용: 반경 내 최저HP 아군(자신 포함, 부상자)에 heal_per_sec*dt.
func _heal(dt: float) -> void:
	var target := _lowest_hp_ally(true)
	if target != null:
		target.heal_received(def.heal_per_sec * dt)

## 최저 HP 비율 아군. within_radius=true면 heal_radius 내 부상자만. 무녀 제외(동료+자신).
func _lowest_hp_ally(within_radius: bool) -> Companion:
	var best: Companion = null
	var best_ratio := INF
	for a in allies:
		if a == null or a.def == null:
			continue
		if within_radius:
			if a.hp >= a.def.max_hp:
				continue
			if global_position.distance_to(a.global_position) > def.heal_radius:
				continue
		var ratio: float = a.hp / a.def.max_hp
		if ratio < best_ratio:
			best_ratio = ratio
			best = a
	return best

## 무녀 방향 약한 이동(재집결/대기). 가까우면 정지.
func _toward_mudang_soft() -> Vector2:
	if mudang == null:
		return Vector2.ZERO
	var to := mudang.global_position - global_position
	if to.length() < 40.0:
		return Vector2.ZERO
	return to.normalized() * def.move_speed * 0.5

## 동료끼리 겹침 분리(가벼운 스티어링). 자신/무효 제외.
func _separation() -> Vector2:
	var push := Vector2.ZERO
	for a in allies:
		if a == self or a == null:
			continue
		var off: Vector2 = global_position - a.global_position
		var dist := off.length()
		if dist > 0.01 and dist < SEPARATION_RADIUS:
			push += off.normalized() * ((SEPARATION_RADIUS - dist) / SEPARATION_RADIUS) * SEPARATION_FORCE
	return push

## leash 고무줄: 무녀에서 leash_radius 초과 시 무녀 방향 가중 추가(모여라보다 약하게).
func _apply_leash(vel: Vector2) -> Vector2:
	if mudang == null or def.leash_radius <= 0.0:
		return vel
	if global_position.distance_to(mudang.global_position) <= def.leash_radius:
		return vel
	var pull := (mudang.global_position - global_position).normalized() * def.move_speed
	return (vel + pull * LEASH_PULL).limit_length(def.move_speed)

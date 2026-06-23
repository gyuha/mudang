## 무녀 — 플레이어 액터(플레이스홀더 표현). ([docs/06]§3, 이동속도 [docs/01]§7/[docs/09]§0)
## 공격 없음. 이동만(오라/넉백/모여라는 후속 슬라이스). InputAdapter.move_vector를 읽어 이동.
class_name Mudang
extends Node2D

## 이동속도 px/s ([docs/01]§7, [docs/09]§0)
const MOVE_SPEED: float = 220.0
## 플레이스홀더 한 변 px (아트 에셋 없음)
const PLACEHOLDER_SIZE: float = 24.0
## 최대 HP ([docs/00] D6-a, [docs/09]§0). 무녀 사망=패배.
const MAX_HP: float = 100.0

## 현재 HP. 적 접촉 시 contact_damage/s로 감소.
var hp: float = MAX_HP
## 머리 위 HP 바(HUD). RunScene이 매 프레임 refresh_hp_bar()로 갱신.
var hp_bar: HpBar

## --- 레버 파라미터(M3, @export 튜닝값 — M5 업그레이드가 런타임 델타 적용). 시작값 [docs/01]·[docs/09] ---
## 오라: 반경 내 적 이동속도 ×slow_multiplier ([docs/01]§2)
@export var aura_radius: float = 140.0
@export_range(0.0, 1.0) var slow_multiplier: float = 0.6
## 「물렀거라」 넉백 ([docs/01]§3)
@export var knockback_radius: float = 90.0
@export var knockback_force: float = 380.0
@export var knockback_cooldown: float = 1.2
@export var max_cast_dist: float = 320.0
## 혼불 자석·전달 ([docs/01]§4, [docs/03]§1)
@export var pickup_radius: float = 70.0
@export var transfer_range: float = 110.0
@export var transfer_rate_max: float = 12.0
## 모여라 ([docs/01]§5)
@export var rally_duration: float = 4.0
@export var rally_cooldown: float = 18.0
## 부활 채널(M4, D13) ([docs/02]§5)
@export var revive_range: float = 100.0
@export var revive_channel_time: float = 3.0

## --- 성장(M5 로직) ---
## 무녀 레벨(시작 1).
var mudang_level: int = 1
## 현재 레벨 내 누적 EXP(무녀 혼불 흡수분).
var mudang_exp: float = 0.0
## 미선택 레벨업 횟수(3택 대기 — UI는 M5-UI Non-goal, 헤드리스/런은 auto-pick).
var _pending_picks: int = 0
## 보유 동료 혼불(근접 동료에 자동 전달 대기).
var companion_soulfire_held: float = 0.0

## 다음 레벨까지 필요 EXP. ([docs/01]§6: floor(8*1.15^(n-1)))
func exp_to_next(n: int) -> int:
	return int(floor(8.0 * pow(1.15, n - 1)))

## EXP 적립(혼불 흡수가 호출). 임계 도달 시 레벨업+pending(초과분 이월). ([docs/03]§2)
func add_exp(v: float) -> void:
	mudang_exp += v
	while mudang_exp >= float(exp_to_next(mudang_level)):
		mudang_exp -= float(exp_to_next(mudang_level))
		mudang_level += 1
		_pending_picks += 1

func pending_picks() -> int:
	return _pending_picks

## 업그레이드 적용 + pending 1 소비(3택 선택의 결과 — auto-pick/UI 공통 진입점).
func apply_upgrade(up: MudangUpgrade) -> void:
	up.apply_to(self)
	_pending_picks = max(0, _pending_picks - 1)

## 접촉 피해 적용(초당 값 × dt를 호출자가 전달). HP는 0 미만으로 안 내려간다.
func take_contact_damage(amount: float) -> void:
	hp = max(0.0, hp - amount)

func _ready() -> void:
	# 코드로 플레이스홀더 그리기(아트 에셋 없이). 중심 정렬된 ColorRect.
	var rect := ColorRect.new()
	rect.color = Color(0.9, 0.3, 0.5)
	rect.size = Vector2(PLACEHOLDER_SIZE, PLACEHOLDER_SIZE)
	rect.position = -rect.size * 0.5
	add_child(rect)

	# 머리 위 HP 바(HUD 슬라이스).
	hp_bar = HpBar.new()
	add_child(hp_bar)

## HP 바 갱신(RunScene가 매 프레임 호출). 무녀는 전투불능 상태 없음.
func refresh_hp_bar() -> void:
	hp_bar.set_ratio(hp / MAX_HP)

func _physics_process(delta: float) -> void:
	position += InputAdapter.move_vector * MOVE_SPEED * delta

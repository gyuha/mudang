## 런 1회의 월드 루트. ([docs/06]§3 씬 트리)
## M0: Camera2D(무녀 추적) + Mudang + 입력 디버그 라벨.
## M1 추가: EnemySystem(단순 풀링 백엔드) + 스폰 포인트(우물 상시 + 크랙 시간차 개방) +
##         잡귀 추격(최근접 아군 타겟=무녀) + 무녀 접촉 피해. ([docs/04] D24, [docs/06]§2, [docs/00] D6-a)
## 노드 트리는 코드로 구성한다(손작성 .tscn 회피).
## M6: StageDef 데이터 주도 — WaveDirector(타임라인+예산) 스폰 + 거점(defend_target) + 목표/승패. ([docs/04][docs/09]§5, D14·D18)
class_name RunScene
extends Node2D

## 슬라이스 스테이지 데이터(M6 — 이 한 파일로 6분 런이 굴러간다). ([docs/05], stage_hwalinseo)
const STAGE_PATH: String = "res://data/stages/stage_hwalinseo.tres"
## 동료 데이터 3종(M2 슬라이스 출전 풀 — 편성 화면은 M7 Non-goal). ([docs/09]§1, D20)
const COMPANION_PATHS: Array[String] = [
	"res://data/companions/hwarang.tres",
	"res://data/companions/hwaljabi.tres",
	"res://data/companions/gyeonseup.tres",
]
## 무녀 기준 동료 시작 배치 오프셋 px.
const COMPANION_OFFSETS: Array[Vector2] = [
	Vector2(-80, 0), Vector2(80, -40), Vector2(0, 80),
]
## 무녀 업그레이드 풀(M5 대표 4카드 — 전체 풀은 데이터 추가, D4). ([docs/09]§4)
const MUDANG_UPGRADE_PATHS: Array[String] = [
	"res://data/upgrades/mudang/aura_expand.tres",
	"res://data/upgrades/mudang/aura_deepen.tres",
	"res://data/upgrades/mudang/knockback_power.tres",
	"res://data/upgrades/mudang/transfer_speed.tres",
]
var _mudang: Mudang
var _camera: Camera2D
var _debug_label: Label
var _enemies: EnemySystem
## 스테이지 데이터 + 웨이브 디렉터 + 거점(M6).
var _stage: StageDef
var _wave: WaveDirector
var _stronghold: Stronghold
## 런 결과: none|win|lose (ObjectiveEval). 결정 시 GameState RESULT 전이 + 시뮬 정지.
var _result: StringName = &"none"
## 메타 저장 1회 가드(M7 — 승리 정산 중복 방지).
var _meta_saved: bool = false
## 출전 동료(M2). 적의 타겟이자 화력원.
var _companions: Array[Companion] = []
## 혼불 시스템(M3).
var _soulfire: SoulfireSystem
## 레버 런타임 상태(M3): 넉백/모여라 쿨다운 잔여 s. 파라미터는 Mudang(@export)가 소유.
var _knockback_cd: float = 0.0
var _rally_cd: float = 0.0
## 무녀 업그레이드 풀(M5) + 카드별 현재 레벨({id: level}).
var _mudang_upgrades: Array[MudangUpgrade] = []
var _mudang_upgrade_levels: Dictionary = {}

## 스폰 포인트 위치(WaveDirector가 라운드로빈 사용). 마커는 _setup_spawn_points가 함께 생성. ([docs/04] D24)
var _spawn_points: Array[Vector2] = []
var _run_time: float = 0.0

func _ready() -> void:
	# 월드 고정 배경 그리드(첫 자식 = 뒤에 깔림). 이동 관측용 정적 기준 — 아트 배경 들어오면 교체.
	add_child(BgGrid.new())

	_mudang = Mudang.new()
	add_child(_mudang)

	# 무녀를 추적하는 카메라. 무녀 자식으로 붙여 위치를 따라가게 한다.
	_camera = Camera2D.new()
	_camera.enabled = true
	_mudang.add_child(_camera)

	# 적 시스템. 아군 타겟은 동료(M2: 무녀 직접 타겟 아님 — D6-a/[docs/04]). 동료 생성 후 등록.
	_enemies = EnemySystem.new()
	add_child(_enemies)

	_spawn_companions()

	# 혼불 시스템(M3). 적 사망 드랍 훅 연결.
	_soulfire = SoulfireSystem.new()
	add_child(_soulfire)
	_enemies.on_kill = _soulfire.spawn_from_drop

	# 무녀 업그레이드 풀(M5). 카드별 레벨 0에서 시작.
	for p in MUDANG_UPGRADE_PATHS:
		var up := load(p) as MudangUpgrade
		_mudang_upgrades.append(up)
		_mudang_upgrade_levels[up.id] = 0

	_setup_spawn_points()

	# 거점(M6 defend_target): 맵 중앙. 적이 타겟하고 접촉 시 HP 감소, 0이면 패배. ([docs/09]§3)
	_stronghold = Stronghold.new()
	_stronghold.position = Vector2.ZERO
	add_child(_stronghold)
	# 적 타겟 = 동료 + 거점(매 프레임 재구성은 _physics_process에서; 초기값도 채움).
	_enemies.ally_targets = []
	for c in _companions:
		_enemies.ally_targets.append(c)
	_enemies.ally_targets.append(_stronghold)

	# 웨이브 디렉터(M6): StageDef 데이터로 타임라인+예산 스폰. ([docs/04]§2, D18)
	_stage = load(STAGE_PATH) as StageDef
	_wave = WaveDirector.new()
	add_child(_wave)
	_wave.setup(_stage, _enemies, _spawn_points)

	# 입력 디버그 라벨(M0). CanvasLayer에 올려 카메라 이동과 무관하게 화면 고정.
	var ui_layer := CanvasLayer.new()
	add_child(ui_layer)
	_debug_label = Label.new()
	_debug_label.position = Vector2(8, 8)
	ui_layer.add_child(_debug_label)

## 동료 3인 스폰: 무녀 근처 하드코딩 배치(편성 화면·슬롯은 M7 Non-goal). ([docs/09]§1, D20)
## 서로를 같은 편 목록(allies, 자신 포함)으로 공유 — 힐 대상/분리용.
func _spawn_companions() -> void:
	for i in COMPANION_PATHS.size():
		var cdef := load(COMPANION_PATHS[i]) as CompanionDef
		var c := Companion.new()
		c.def = cdef
		c.enemies = _enemies
		c.mudang = _mudang
		c.position = _mudang.position + COMPANION_OFFSETS[i]
		add_child(c)
		_companions.append(c)
	# 같은 편 목록 공유(자신 포함).
	for c in _companions:
		c.allies = _companions

## 스폰 포인트 배치(우물 2 + 크랙 3) — 위치 목록 + 플레이스홀더 마커. WaveDirector가 위치를 사용. ([docs/04] D24)
## (M1의 크랙 시간차 개방은 M6의 타임라인/예산 페이싱으로 대체 — 위치만 남김.)
func _setup_spawn_points() -> void:
	_add_spawn_point(Vector2(-400, -250), "well")
	_add_spawn_point(Vector2(420, 300), "well")
	_add_spawn_point(Vector2(350, -350), "crack")
	_add_spawn_point(Vector2(-450, 320), "crack")
	_add_spawn_point(Vector2(0, 450), "crack")

func _add_spawn_point(pos: Vector2, kind: String) -> void:
	_spawn_points.append(pos)
	var marker := _SpawnMarker.new()
	marker.position = pos
	marker.kind = kind
	add_child(marker)

func _physics_process(delta: float) -> void:
	# 결과 확정 후 시뮬 정지(승/패 전이 1회). ([docs/04]§3)
	if _result != ObjectiveEval.NONE:
		return
	_run_time += delta

	# 웨이브 디렉터(M6): StageDef 타임라인+예산 데이터 주도 스폰. ([docs/04]§2, D18)
	_wave.tick(delta, _run_time)

	# 레버 쿨다운 감소(M3).
	_knockback_cd = max(0.0, _knockback_cd - delta)
	_rally_cd = max(0.0, _rally_cd - delta)

	# 적 타겟 재구성: 전투 가능한 동료(쓰러짐/상실 제외) + 거점(미파괴). ([docs/02]§4, [docs/09]§3)
	_enemies.ally_targets.clear()
	for c in _companions:
		if not c.is_incapacitated():
			_enemies.ally_targets.append(c)
	if not _stronghold.is_destroyed():
		_enemies.ally_targets.append(_stronghold)

	# 오라(레버1): 무녀 기준 감속장을 적 시스템에 주입(tick 전). ([docs/01]§2)
	_enemies.aura_center = _mudang.global_position
	_enemies.aura_radius = _mudang.aura_radius
	_enemies.aura_slow = _mudang.slow_multiplier

	# 적 AI 이동 + 격자 재구축.
	_enemies.tick(delta)

	# 「물렀거라」(레버2): 시전 입력 + 쿨다운 + 사거리 게이트 → 넉백. ([docs/01]§3)
	if InputAdapter.aim_pressed and _knockback_cd <= 0.0:
		var aim := InputAdapter.aim_point
		if _mudang.global_position.distance_to(aim) <= _mudang.max_cast_dist:
			_enemies.apply_knockback(aim, _mudang.knockback_radius, _mudang.knockback_force)
			_knockback_cd = _mudang.knockback_cooldown

	# 동료 AI 한 스텝(RunScene이 틱 소유 — 결정성, EnemySystem.tick과 동일 패턴).
	for c in _companions:
		c.step(delta)

	# 케어(M4): 부활 채널(무녀 정지+근접) + 상실 디버프(혼불 수집 효율↓). ([docs/02]§4·§5)
	_handle_revive(delta)
	var lost := 0
	for c in _companions:
		if c.is_lost():
			lost += 1
	_soulfire.pickup_efficiency = max(0.4, 1.0 - 0.15 * lost)

	# 혼불(레버3): 자석 픽업 + 보유 동료혼불 근접 전달(+소폭 회복). ([docs/01]§4, [docs/03]§1)
	_soulfire.update(delta, _mudang, _companions)

	# 성장(M5): 무녀 레벨업 대기분 auto-pick(3택 UI/일시정지는 M5-UI Non-goal — 흐름 검증용 자동선택).
	_auto_pick_mudang_upgrades()

	# 모여라(레버4): 트리거 + 쿨다운 → 동료 일괄 집결. ([docs/01]§5)
	if InputAdapter.rally_pressed and _rally_cd <= 0.0:
		for c in _companions:
			c.start_rally(_mudang.rally_duration)
		_rally_cd = _mudang.rally_cooldown

	# 접촉 피해(M6: 적별 contact_damage 합산 — 잡귀/처녀귀신/도깨비 혼재). 무녀+동료+거점. ([docs/00] D6-a, [docs/09]§3)
	_mudang.take_contact_damage(_contact_damage_sum(_mudang.global_position) * delta)
	for c in _companions:
		c.take_contact_damage(_contact_damage_sum(c.global_position) * delta)
	_stronghold.take_contact_damage(_contact_damage_sum(_stronghold.global_position) * delta)

	# 목표/승패 평가(M6): 무녀 사망/거점 파괴=패배, duration 도달=승리. ([docs/04]§3, D14)
	_result = ObjectiveEval.evaluate(_run_time, _stage.duration, _mudang.hp, _stronghold.hp)
	if _result != ObjectiveEval.NONE and GameState.state != GameState.S.RESULT:
		GameState.set_state(GameState.S.RESULT)
		# 영구메타 정산·해금(M7): 승리 1회만 저장(편성/결과 UI는 M7-UI Non-goal). ([docs/03]§5)
		if _result == ObjectiveEval.WIN and not _meta_saved:
			var meta := MetaProgress.load_or_new()
			meta.record_clear(_stage, _run_time)
			meta.save()
			_meta_saved = true

## 부활 채널(M4): 무녀가 정지(이동 입력≈0)하고 revive_range 내 쓰러진 동료가 있으면
## 가장 가까운 1명의 게이지를 충전, 그 외 쓰러진 동료는 감쇠. ([docs/02]§5, D13)
func _handle_revive(delta: float) -> void:
	var stationary := InputAdapter.move_vector.length() < 0.01
	var nearest: Companion = null
	var best_d := INF
	for c in _companions:
		if not c.is_downed():
			continue
		var d := _mudang.global_position.distance_to(c.global_position)
		if d <= _mudang.revive_range and d < best_d:
			best_d = d
			nearest = c
	for c in _companions:
		if not c.is_downed():
			continue
		if c == nearest and stationary:
			c.revive_progress(delta, _mudang.revive_channel_time)
		else:
			c.revive_decay(delta)

## 무녀 레벨업 대기분을 풀에서 미만렙 카드로 auto-pick 적용(M5-UI 3택의 헤드리스/런 플레이스홀더).
func _auto_pick_mudang_upgrades() -> void:
	while _mudang.pending_picks() > 0:
		var pick: MudangUpgrade = null
		for up in _mudang_upgrades:
			if _mudang_upgrade_levels[up.id] < up.max_level:
				pick = up
				break
		if pick == null:
			break   # 전부 만렙 — pending 소진 불가, 무한루프 방지
		_mudang.apply_upgrade(pick)
		_mudang_upgrade_levels[pick.id] += 1

## center 주변 접촉 반경 내 적들의 contact_damage 합(초당). 적 종류 혼재 대응. ([docs/09]§2)
func _contact_damage_sum(center: Vector2) -> float:
	var total := 0.0
	for idx in _enemies.query_circle(center, EnemySystem.CONTACT_RADIUS):
		total += _enemies.def_of(idx).contact_damage
	return total

func _process(_delta: float) -> void:
	# HP 바 갱신(HUD 슬라이스): 무녀 + 동료 머리 위 바.
	_mudang.refresh_hp_bar()
	for c in _companions:
		c.refresh_hp_bar()

	var comp_lines := ""
	for c in _companions:
		comp_lines += "\n  %s HP:%d/%d [%s] Lv%d pend%d" % [
			c.def.display_name, int(c.hp), int(c.def.max_hp), c.state_name(),
			c.companion_level, c.pending_upgrades,
		]
	_debug_label.text = "무녀 HP: %d/%d  Lv%d EXP:%d/%d\n거점 HP: %d/%d  결과:%s\n적 수: %d / %d  혼불모트:%d\n혼불 보유:%.0f  넉백쿨:%.1f  모여라쿨:%.1f\n런 시간: %.1f/%.0fs\n동료:%s" % [
		int(_mudang.hp), int(Mudang.MAX_HP), _mudang.mudang_level,
		int(_mudang.mudang_exp), _mudang.exp_to_next(_mudang.mudang_level),
		int(_stronghold.hp), int(_stronghold.max_hp), _result,
		_enemies.active_count(), EnemySystem.CAP, _soulfire.active_count(),
		_mudang.companion_soulfire_held, _knockback_cd, _rally_cd,
		_run_time, _stage.duration,
		comp_lines,
	]

## 스폰 포인트 플레이스홀더 마커(솟는 위치 가시화). 우물=원, 크랙=사각.
class _SpawnMarker extends Node2D:
	var kind: String = "well"
	func _draw() -> void:
		if kind == "well":
			draw_circle(Vector2.ZERO, 20.0, Color(0.9, 0.85, 0.3, 0.7))
		else:
			draw_rect(Rect2(-18, -14, 36, 28), Color(0.9, 0.5, 0.2, 0.7))

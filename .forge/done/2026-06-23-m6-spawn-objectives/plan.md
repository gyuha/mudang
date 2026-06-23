<!-- forge-slug: m6-spawn-objectives -->
<!-- task: 7 -->
<!-- priority: high -->
<!-- tdd: off -->
# M6 스폰·목표 — WaveDirector · 거점 · 승/패

## Goal / Non-goals
- Goal: 하드코딩 스폰을 **StageDef 데이터 주도 WaveDirector**(타임라인+예산 하이브리드)로 대체하고, **거점(defend_target)** + **목표/승패 판정**을 붙여 `stage_hwalinseo.tres` 하나로 6분 런이 굴러가고 승/패가 난다. (docs/04 §2·§3, docs/09 §3·§5, docs/05, D14·D18·D24)
- Non-goals (**human/GUI wall**):
  - 500@60fps 실측(M-S, GUI), HUD/거점 HP바 연출(M8), 편성 화면(M7), 결과 화면 UI(M7/M8 — 헤드리스는 GameState 전이만)
  - 거점 타겟 비율 정밀화(20%/40% docs/09§3)는 M8 밸런스 — M6는 거점을 ally_target에 포함(최근접 타겟팅)

## Source of truth
- Glossary terms: 거점=defend_target, 웨이브 디렉터=WaveDirector(docs/00 §3). `.forge/CONTEXT.md` 미생성.
- Related ADRs: docs/00 §2 — **D18**(하이브리드 스폰), **D14**(시간제 생존+목표), **D24**(스폰 포인트). 데이터/수치: docs/09 §5(timeline·budget), docs/04 §2·§3, stage_hwalinseo.tres(완비).
- Definition of Done: `tools/test/wave_objective_check` 헤드리스 PASS — (1) WaveDirector가 예산으로 적을 스폰하고 타임라인 이벤트(t=90 ghost×8 등)가 정시 발동, (2) 거점이 접촉피해로 HP 감소·0이면 lose, (3) survive duration 도달 시 win, (4) 무녀 사망 시 lose. M1~M5 회귀 정상.

## Work slices
- [ ] S1. `WaveDirector`(`scripts/systems/wave_director.gd`): StageDef·EnemySystem·스폰포인트 주입. 타임라인 채널(time 도달 시 SPAWN_GROUP/MINIBOSS/RUSH = enemy×count 1회 발동) + 예산 채널(budget_per_sec(t) 누적 → 활성 spawn_pool 가중추첨, spawn_cost 소비). max_active 클램프 — completion criterion: 시간 진행 시 예산 스폰 발생 + t=90에 ghost 8 추가 등 타임라인 정시 발동(헤드리스 PASS)
- [ ] S2. `Stronghold`(`scripts/actors/stronghold.gd`, Node2D): hp(300)/take_contact_damage/플레이스홀더. 맵 중앙 배치, EnemySystem.ally_targets에 포함(적이 거점도 타겟) — completion criterion: 거점 근처 적이 거점을 향하고 접촉 시 HP 감소(헤드리스 PASS)
- [ ] S3. 목표/승패: `ObjectiveEval.evaluate(run_time, duration, mudang_hp, stronghold_hp)` 순수 함수(무녀 사망/거점 파괴=lose, duration 도달=win, 그 외 none). RunScene가 매 프레임 평가 → 결과 시 GameState.set_state(RESULT) + 결과 저장 — completion criterion: 4 분기(win/lose×2/none)가 정확(헤드리스 PASS) (depends: S2)
- [ ] S4. RunScene 통합: stage_hwalinseo.tres 로드, 하드코딩 스폰 제거 → WaveDirector 구동, 거점 추가, 매 프레임 거점 접촉피해 + 결과 평가. 디버그 라벨에 거점 HP/목표/결과 — completion criterion: stage 데이터 하나로 런이 굴러가고 승/패 전이(통합 체크) (depends: S1, S2, S3)
- [ ] S5. 헤드리스 체크 `tools/test/wave_objective_check.*`(예산스폰/타임라인/거점피해/4승패분기) + import 선행 + M1~M5 회귀 — completion criterion: `godot --headless` 전 체크 PASS, 회귀 정상 (depends: S4)

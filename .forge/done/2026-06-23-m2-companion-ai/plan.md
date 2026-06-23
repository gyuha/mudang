<!-- forge-slug: m2-companion-ai -->
<!-- task: 3 -->
<!-- priority: high -->
<!-- tdd: off -->
# M2 동료 AI — 공통 FSM + 탱/딜/힐 3역할 자율 전투

## Goal / Non-goals
- Goal: 단일 `CompanionDef`(role_id 분기, D25) 기반으로 동료 3인(화랑/활잡이/견습무당)이 공통 FSM(`ACQUIRE→ENGAGE→REPOSITION`)으로 **역할대로 자율 전투**한다. 탱=전열+도발, 딜=카이팅+원거리, 힐=최저HP 아군 회복(지원 전용). 적은 무녀가 아닌 **동료를 타겟**한다. separation·leash로 군집을 유지한다. (docs/02, docs/07 M2, docs/09 §1)
- Non-goals (마일스톤 경계):
  - RALLY 상태/「모여라」 — M3 (enum 값만 선언, 트리거 없음)
  - DOWNED/LOST/부활, **동료 HP 0 사망 처리** — M4 (M2에선 HP 음수 클램프, 죽지 않음)
  - 성장 3택 / `CompanionUpgrade` — M5
  - 관통2 · 투사체 · 셰이더/파티클 연출 — M8 (즉시판정으로 대체)
  - 정화(cleanse) — 대상(역병귀)이 슬라이스에 없음, 연기
  - 편성/슬롯 화면 — M7 (3인 하드코딩 스폰)
  - 미니맵 쓰러짐 알림 — M4/M8
  - 500마리 스케일 — M-S (현 ~150 백엔드 유지)
  - 거점 `defend_target` — M6

## Source of truth
- Glossary terms: none (프로젝트 용어집은 `docs/00 §3`가 권위 — 동료/Companion, 오라, 모여라 등). `.forge/CONTEXT.md`는 중복 방지로 생성하지 않음.
- Related ADRs: 프로젝트 결정 로그 `docs/00 §2` — **D25**(단일 CompanionDef), **D9**(역할 교전·자가후퇴 없음), **D20**(슬라이스 풀 탱/딜/힐), **D6-a**(접촉 피해). 수치는 `docs/09 §1`이 단일 권위.
- Definition of Done: `tools/test/companion_*` 헤드리스 체크 씬이 **전부 PASS** — 동료 3인이 역할대로 자율 전투(탱 전열/딜 카이팅/힐 회복)하고, 적이 동료를 타겟하며, 도발·separation·leash가 작동한다.

## Work slices
- [ ] S1. `CompanionDef` 리소스(`scripts/data/companion_def.gd`, `class_name CompanionDef extends Resource`) + 인스턴스 3종(`data/companions/{hwarang,hwaljabi,gyeonseup}.tres`). 필드/수치는 docs/02 §2 예시 + docs/09 §1 표(견습무당 `attack_damage=0` 지원 전용). 기존 `EnemyDef` 컨벤션(`##` 주석, StringName id, snake_case, 탭) 준수 — completion criterion: 3 .tres가 에러 없이 로드되고 role_id/주요 스탯이 docs/09 값과 일치(헤드리스 로드 체크 PASS)
- [ ] S2. `Companion` 액터(`scripts/actors/companion.gd`, `class_name Companion extends Node2D`) + 공통 FSM 3상태(`ACQUIRE→ENGAGE→REPOSITION`; RALLY/DOWNED/LOST는 enum만). `_physics_process` 0.15s 누적 결정 틱 + 매 프레임 이동. EnemySystem `query_circle`/`position_of`로 근처 적만 스캔(전체 스캔 금지) — completion criterion: 동료가 최근접 적을 ACQUIRE해 `attack_range`까지 접근(헤드리스 체크 PASS) (depends: S1)
- [ ] S3. 역할 거동 + 즉시판정 전투. 탱: `attack_period`마다 `attack_range` 내 타겟에 `apply_damage`. 딜: 우선순위(ELITE>NEAREST) 타겟, `attack_range` 320 사격, 적이 `kite_min` 80 내 진입 시 무녀 방향 REPOSITION 후퇴. 힐: `heal_radius` 140 내 **최저HP 아군(동료+자신, 무녀 제외)**에 `heal_per_sec` 적용, 적 공격 없음 — completion criterion: 탱·딜이 적 HP 감소시킴(`active_count`↓), 딜 카이팅 후퇴 관측, 피해 입은 동료가 힐러 근처서 HP 회복(헤드리스 체크 PASS) (depends: S2)
- [ ] S4. `EnemySystem.ally_targets`를 동료 3인으로 전환(무녀 제거) + 도발 오버라이드: 적이 어떤 탱의 `taunt_radius` 내면 타겟을 그 탱으로(없으면 최근접 동료) — completion criterion: 적이 동료로 직진하고, 도발 반경 내 적이 탱으로 향함(헤드리스 체크 PASS) (depends: S2)
- [ ] S5. separation(동료·적 가벼운 분리) + leash 고무줄(무녀에서 `leash_radius` 360 밖이면 무녀 가중 이동, 모여라보다 약하게). NavMesh 미사용, 직진+분리 스티어링(docs/02 §3) — completion criterion: 겹친 두 동료가 서로 밀어내고, leash 밖 동료가 무녀 쪽으로 당겨짐(헤드리스 체크 PASS) (depends: S2)
- [ ] S6. `run_scene.gd` 통합 — 시작 시 무녀 근처에 동료 3인 스폰, `ally_targets` 등록(S4), 무녀 접촉피해 질의는 유지. 디버그 라벨에 동료 상태/HP 추가 — completion criterion: 런 실행 시 동료 3인이 자율 전투하며 적을 처치(육안/헤드리스 통합 체크) (depends: S3, S4, S5)
- [ ] S7. 헤드리스 체크 씬(`tools/test/companion_*.tscn`+`.gd`, M1 패턴) — S1~S6의 어서션을 자동 검증(로드·acquire·전투·카이팅·도발·separation·leash·힐). 어서션 실패 시 비정상 종료/에러 출력 — completion criterion: `godot --headless`로 전 체크 씬 PASS (depends: S6)

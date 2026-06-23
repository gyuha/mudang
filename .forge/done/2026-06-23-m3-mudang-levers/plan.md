<!-- forge-slug: m3-mudang-levers -->
<!-- task: 4 -->
<!-- priority: high -->
<!-- tdd: off -->
# M3 무녀 레버 4종 — 오라 · 넉백 · 혼불 전달 · 모여라

## Goal / Non-goals
- Goal: 무녀의 능동 도구 4 레버를 구현해 **동료 생존·적 거동에 실제로 영향**을 주게 한다. (1) 오라=패시브 감속장, (2) 「물렀거라」=클릭 넉백(능동), (3) 혼불 전달=근접 자동 자원배분(+소폭 회복), (4) 모여라=쿨다운 집결. 입력은 기존 `InputAdapter` 추상 3종(aim/rally/move) 사용. (docs/01, docs/03 §1, 수치 docs/09 §0·§4, D6·D6-a·D8·D10)
- Non-goals (마일스톤 경계, Q1 확정):
  - 무녀 EXP→**레벨업/일시정지 3택**, 동료 EXP→**비정지 보류카드/UI** — M5 (M3는 EXP **카운터 적립만**)
  - 오라 **레벨 보정**(enemy_lv vs mudang_lv) — M5 (mudang_lv=1, 단순 감속)
  - 무녀 **생존 카드/정화/봉인** 등 업그레이드 — M5
  - 혼불 **연출·자석 트레일·셰이더**, 미니맵 — M8
  - 거점 `defend_target` — M6 · 쓰러짐/부활 — M4(이미 분리) · 모바일 입력 — 후속

## Source of truth
- Glossary terms: none (프로젝트 용어집 `docs/00 §3`: 오라/물렀거라/혼불/혼불전달/모여라가 권위). `.forge/CONTEXT.md` 미생성.
- Related ADRs: 프로젝트 결정 로그 `docs/00 §2` — **D6**(무공격 서포터, 레버 4개), **D6-a**(무녀 HP/접촉피해), **D8**(모여라 단일), **D10**(혼불 2종·자동전달·전달=EXP+소폭회복). 수치는 `docs/09 §0·§4` + `docs/01`이 권위.
- Definition of Done: `tools/test/mudang_levers_check` 헤드리스 PASS — 오라(반경 내 적 감속), 넉백(반경 내 적 바깥 변위 + resist 차등 + 쿨다운 게이트), 혼불 전달(보유→근접 동료 HP 회복 + proximity 속도), 모여라(동료가 무녀로 수렴 후 자율 복귀)가 각각 관측되고, M1/M2 회귀 정상.

## Work slices
- [ ] S1. `Mudang`에 레버 파라미터 `@export`(aura_radius=140/slow_multiplier=0.6, knockback radius=90/force=380/cooldown=1.2/max_cast_dist=320, pickup_radius=70, transfer_range=110/transfer_rate_max=12, rally_duration=4/rally_cooldown=18) + 카운터(mudang_exp, companion_soulfire_held) + 쿨다운 타이머 상태. docs/09·01 시작값 — completion criterion: export 값이 docs 시작값과 일치하고 헤드리스 로드 무오류
- [ ] S2. 오라 — `EnemySystem.tick`이 무녀 `aura_radius` 내 적 이동속도에 `slow_multiplier` 곱적용(매 적 Area2D 금지, spatial hash/거리검사). 무녀 참조/오라 파라미터 주입 — completion criterion: 반경 내 적 실효 속도가 (1-감속)배로 줄고 반경 밖은 불변(헤드리스 체크 PASS) (depends: S1)
- [ ] S3. 넉백 — `EnemySystem.apply_knockback(center, radius, force)`: 반경 내 적을 바깥으로 `force*(1-knockback_resist)` 변위 + `0.15s` 경직(SoA 경직 타이머 → tick 이동 스킵). `Mudang`이 쿨다운(1.2s)·`max_cast_dist`(320) 게이트로 시전, `RunScene`이 `aim_pressed`/`aim_point` 배선 — completion criterion: 시전 시 반경 내 적이 바깥으로 밀리고 resist 높은 적은 덜 밀림, 쿨다운 중 재시전 무효(헤드리스 체크 PASS) (depends: S1)
- [ ] S4. 혼불 — 신규 경량 `SoulfireSystem`(pos/kind/amount 배열 + 플레이스홀더, swap-remove). `EnemySystem._kill`이 죽은 적 위치+`DropTable`로 드랍 요청(콜백/시그널). 무녀 `pickup_radius` 자석: 무녀혼불=즉시흡수(mudang_exp++)/동료혼불=보유++. 보유 동료혼불 → `transfer_range` 내 최근접 1동료에 `rate=transfer_rate_max*clamp(1-d/range,0,1)` 전달 → `companion.heal_received(+0.5/전달량)` + 동료 EXP 카운터++ — completion criterion: 적 처치→혼불 스폰→무녀 자석 픽업→근접 동료 HP 회복, 가까울수록 전달 빠름(헤드리스 체크 PASS) (depends: S1)
- [ ] S5. 모여라 — `RunScene`이 rally 활성/쿨다운(4s/18s) 관리(`rally_pressed` 트리거), `Companion`이 rally 플래그로 **RALLY 상태**(M2 enum 배선): 이동목표에 무녀 방향 가중 추가(교전 유지), duration 종료 시 ACQUIRE 자율 복귀 — completion criterion: 모여라 발동 후 동료들이 무녀로 수렴하고 종료 후 흩어져 교전 복귀, 쿨다운 중 재발동 무효(헤드리스 체크 PASS) (depends: S1)
- [ ] S6. `RunScene` 통합 — 매 프레임 레버 입력 배선(오라 주입·넉백 시전·혼불 구동·모여라), SoulfireSystem 추가, 디버그 라벨에 혼불 보유/EXP/넉백 쿨/모여라 상태 추가 — completion criterion: 실제 런에서 4 레버가 동시 작동(육안/헤드리스 통합 체크) (depends: S2, S3, S4, S5)
- [ ] S7. 헤드리스 체크 씬(`tools/test/mudang_levers_check.*`, M1/M2 패턴) — 오라·넉백·전달·모여라 어서션. 신규 class_name import 패스 선행(M0/M2 학습). + M1/M2 회귀 확인 — completion criterion: `godot --headless` 전 체크 PASS, M1·M2 체크 회귀 정상 (depends: S6)

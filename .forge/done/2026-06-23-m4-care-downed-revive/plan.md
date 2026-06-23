<!-- forge-slug: m4-care-downed-revive -->
<!-- task: 5 -->
<!-- priority: high -->
<!-- tdd: off -->
# M4 케어 — 쓰러짐 · 부활 · 상실

## Goal / Non-goals
- Goal: 동료 HP 0이 즉사가 아니라 **쓰러짐(DOWNED)**이 되고, 무녀가 근접 채널링으로 **부활(Revive)**, 방치 시 **상실(LOST)**되며 런 디버프가 적용된다. M2의 "HP 0=클램프, 죽지 않음"을 실제 케어 루프로 대체. (docs/02 §4·§5, D13)
- Non-goals:
  - 머리 위 카운트다운 링·화면 밖 화살표·미니맵 펄스/핑/해골 — 연출/UI는 M8 (헤드리스는 타이머/상태 로직만 검증)
  - 성장/레벨업(M5), 거점(M6), 모바일 입력

## Source of truth
- Glossary terms: none (docs/00 §3: 쓰러짐/부활이 권위). `.forge/CONTEXT.md` 미생성.
- Related ADRs: docs/00 §2 — **D13**(무녀 근접 채널링 부활), **D9**(생존은 플레이어 책임). 수치 docs/02 §4·§5 (downed_timer 8s / revive_range 100 / revive_channel_time 3s / 부활 HP 40%).
- Definition of Done: `tools/test/care_check` 헤드리스 PASS — (1) 치명피해→DOWNED(즉사 아님, 무적), (2) 무녀 정지 근접 채널→게이지 충전→부활(40% HP, ACQUIRE 복귀), (3) 이탈 시 채널 감쇠·부활 안 됨, (4) downed_timer 초과→LOST + 런 디버프(혼불 수집 효율↓) 적용. M1~M3 회귀 정상.

## Work slices
- [ ] S1. Companion 쓰러짐: `take_contact_damage`에서 hp<=0 → `_enter_downed()`(_state=DOWNED, downed_timer 8s 시작). DOWNED/LOST 중 무적(추가 피해 무시)·전투/이동 정지. step()에서 downed_timer 감소 → 0이면 LOST. `is_downed()`/`is_lost()` 헬퍼 — completion criterion: 치명피해 시 제거 안 되고 DOWNED, 추가 피해 무효, 타이머 0에서 LOST (헤드리스 PASS)
- [ ] S2. 부활 채널링: Companion `revive_progress(dt)`(게이지+, 충전 완료 시 hp=max×0.4 + _state=ACQUIRE 복귀, true 반환) / `revive_decay(dt)`(이탈 시 게이지 감쇠). Mudang `revive_range`(100)/`revive_channel_time`(3.0) `@export` — completion criterion: 정지 채널 revive_channel_time 누적 시 40% HP로 부활, 도중 이탈 시 감쇠로 미부활 (헤드리스 PASS) (depends: S1)
- [ ] S3. RunScene 케어 배선: 매 프레임 무녀 정지(move_vector≈0) + revive_range 내 최근접 DOWNED 동료 → revive_progress, 아니면 decay. ally_targets/접촉피해 대상에서 DOWNED/LOST 제외(적이 쓰러진 동료 무시). 부활 시 ally_targets 재포함 — completion criterion: 런에서 무녀가 곁에 머물면 부활, 떠나면 진행 안 됨; 쓰러진 동료는 적 타겟서 빠짐 (통합 체크) (depends: S2)
- [ ] S4. 상실 디버프: RunScene이 LOST 수 추적 → SoulfireSystem `pickup_efficiency = max(0.4, 1-0.15*lost)` 주입(혼불 수집 효율↓). 화력 감소는 동료 상실로 자동(전투 이탈) — completion criterion: LOST 발생 시 혼불 흡수량이 효율 배수만큼 감소 (헤드리스 PASS) (depends: S1)
- [ ] S5. 헤드리스 체크 `tools/test/care_check.*` (downed/revive/decay/lost+debuff) + import 선행 + M1~M3 회귀 — completion criterion: `godot --headless` 전 체크 PASS, 회귀 정상 (depends: S3, S4)

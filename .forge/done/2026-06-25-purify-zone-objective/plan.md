<!-- forge-slug: purify-zone-objective -->
<!-- task: 26 -->
<!-- tdd: off -->
<!-- priority: medium -->
<!-- generated-by: fg-loop -->
# purify_zone 목표 메커닉 — 구역 점거 게이지 + 승리 경로 (계층②)

## Goal / Non-goals
- Goal: purify_zone 목표를 실제 평가 엔진으로 구현. 구역 내 아군(무녀/동료)이 있으면 게이지가 충전(charge_time초에 만충), 스테이지의 모든 purify_zone 목표가 만충되면 승리. 스테이지 4·5의 장식 목표를 실제 승리 경로로 전환.
- Non-goals: 순차(order) 강제 잠금(현재는 동시 충전 허용 — order는 표시용으로 보존), 구역 비주얼/셰이더, 적의 구역 점령 역충전, 시야 제한(계층② 별도).

## Source of truth
- Glossary terms: purify_zone, 점거 게이지 in .forge/CONTEXT.md
- Related ADRs: docs/04 §3(목표), docs/10 §6(계층②), docs/05(ObjectiveDef params)
- Definition of Done: purify_zone_check가 `VERDICT => PASS` — 구역 점거 시 게이지 충전, 전부 만충 시 WIN, 미점거 시 NONE 유지. 기존 survive/defend/kill_boss 회귀 무파손.

## 설계 메모
- **구역 지오메트리 부재 문제**: 현재 purify_zone params는 {order, charge_time}뿐, 위치/반경 없음. params에 `pos`(Vector2 또는 x/y) + `radius` 추가하고 stage 4·5 .tres에 값 부여(맵 내 분산 배치).
- ObjectiveEval/RunScene 확장: purify_zone 목표별 충전 진행도(0~1)를 RunScene가 매 틱 갱신 — 구역 내 아군 수 ≥1이면 dt/charge_time 만큼 증가(상한 1.0). 모든 purify_zone 만충 → 승리. survive_time이 함께 있으면 purify 완료가 승리 트리거(기존 kill_boss 분기와 유사 우선).
- ObjectiveEval.evaluate 시그니처 확장 또는 RunScene에서 purify 완료 여부를 계산해 전달(기존 has_kill_boss 패턴 따름 — has_purify/purify_done).
- 무녀/동료 위치는 RunScene가 보유(_mudang, _companions).

## Work slices
- [ ] S1. tools/test/purify_zone_check.gd+.tscn(먼저) — 완료 기준: purify_zone 목표를 가진 스테이지(또는 임시 StageDef)로 RunScene 구동 → 무녀를 구역 밖에 둘 때 NONE 유지, 구역 안에 두고 충분히 tick → 게이지 만충 → WIN. 현재(미구현)엔 FAIL.
- [ ] S2. ObjectiveDef purify_zone params에 pos/radius 추가 + stage 4·5 데이터 — 완료 기준: 구역 위치/반경 데이터 부여, validate 통과.
- [ ] S3. RunScene + ObjectiveEval purify_zone 평가 — 완료 기준: 구역 점거 충전 + 전부 만충 시 WIN 판정. purify_zone_check PASS.
- [ ] S4. 회귀 무파손 — 완료 기준: 기존 목표(survive/defend/kill_boss) 체크 전부 green(stage*/wave_objective), main 부팅 에러 0.

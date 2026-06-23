<!-- forge-slug: m5-growth-logic -->
# run — M5 성장 로직 (계획 대비 실제)

실행: fg-loop 무인 드라이브. 직접 구현. 검증: 헤드리스 `growth_check`.

## 계획대로 된 것
- S1 MudangUpgrade 리소스(targets/deltas 병렬 배열, apply_to) + 대표 4 .tres(오라확장/오라심화/넉백강화/전달가속) — 전부 Mudang @export 레버 타겟.
- S2 무녀 레벨업: exp_to_next(floor(8*1.15^(n-1))) + add_exp(누적/이월/pending) + apply_upgrade(데이터 주도 set/get). SoulfireSystem 흡수 → add_exp 호출.
- S2b 동료 레벨업 감지: comp_exp_to_next(floor(6*1.18^(n-1))) + add_companion_exp(레벨업→pending_upgrades, 상한 3) + has_pending. SoulfireSystem 전달 → add_companion_exp.
- S3 RunScene auto-pick(미만렙 카드 1개 적용, 만렙 시 break) + 디버그 라벨(무녀 Lv/EXP, 동료 Lv/pending).
- S4 growth_check 4종 PASS.

## 검증 증거 (헤드리스)
- growth_check 4/4 PASS(곡선 8/9/13, 무녀 Lv4/pend3, 적용 +20/+60/+12, 동료 pending 상한3). 회귀 5종 정상. main.tscn 400프레임 런타임 에러 0(레벨업 auto-pick 정상, 무한루프 없음).

## 분기(divergence)
- **D-a. M5는 로직만, UI는 분리(계획대로).** 일시정지 3택·카드 렌더·클릭·비정지 동료 보류카드 UX·"흐름 안 끊김" 체감 = M5-UI human wall. 헤드리스는 곡선/적립/적용만, 선택은 RunScene auto-pick 플레이스홀더.
- **D-b. 동료 업그레이드 APPLY 미구현(계획대로 분리).** 공유 CompanionDef 변이 회피(load 캐시 공유) + 역할별 효과 설계 필요 → 인스턴스 오버라이드 설계는 M5-UI/후속. M5는 동료 레벨업 **감지(pending)**까지.
- **D-c. 대표 4카드만.** 전체 19카드(docs/09§4)는 데이터 추가(D4). 무녀 생존 카드(max_hp)는 현재 const라 제외(HP를 var로 바꾸는 별도 작업).

## 비고 — 다음은 human wall
- ★재미 검증★(M2~M5 플레이테스트), M5-UI(3택/일시정지/체감), M-S(500@60fps GUI), M7(편성 UI), M8(폴리시/밸런스)은 사람/GUI 필요. M6(스폰·목표·승/패)은 헤드리스 가능 — 드라이브 계속 판단.

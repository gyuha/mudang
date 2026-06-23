<!-- forge-slug: m5ui-levelup-choice -->
<!-- task: 12 -->
<!-- tdd: off -->
# M5-UI 무녀 레벨업 3택 일시정지 카드

## Goal / Non-goals
- Goal: 무녀 레벨업 시 게임 일시정지 + 미만렙 업그레이드 3택 카드 → 선택 시 적용. auto-pick 대체. (docs/01§6, docs/03§2, D11·D12)
- Non-goals: 동료 비정지 보류카드 UX(별도), 가중 추첨(슬라이스는 앞에서 3개), 카드 아이콘/연출(M8), 시각 체감(GUI).

## Definition of Done
- levelup_ui_check PASS(후보 ≤3·만렙제외, 선택 시 파라미터+델타·레벨++·pending 소비). 회귀 green, main 에러 0.

## Work slices
- [x] S1. LevelUpChoice(CanvasLayer, PROCESS_MODE_ALWAYS): pick_candidates(미만렙 ≤3) + maybe_show(pending시 일시정지+3버튼) + _on_pick(적용+레벨+닫기)
- [x] S2. RunScene: auto-pick 제거 → _levelup_ui.maybe_show() 배선
- [x] S3. levelup_ui_check + 회귀

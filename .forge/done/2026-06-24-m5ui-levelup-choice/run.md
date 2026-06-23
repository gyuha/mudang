<!-- forge-slug: m5ui-levelup-choice -->
# run — M5-UI 레벨업 3택

실행: fg-loop(/goal), eco on. 직접 구현.

## 계획대로
- LevelUpChoice: pick_candidates(미만렙 앞 3) / maybe_show(get_tree().paused + PanelContainer+버튼) / _on_pick(apply_upgrade+levels+pending 소비+_close 언포즈). PROCESS_MODE_ALWAYS로 포즈 중 입력.
- RunScene: _auto_pick_mudang_upgrades 제거, _levelup_ui.maybe_show() 매 프레임.

## 검증
- levelup_ui_check 2종(후보 3/만렙0, 적용 +20·lvl1·pending--) PASS. 회귀 14종 green, main 200프레임 에러 0.
- 일시정지·렌더·클릭 체감은 GUI 확인.

## 분기
- auto-pick(M5-logic 플레이스홀더) 제거 → 실제 3택. main 헤드리스 스모크는 첫 레벨업에서 일시정지(수동 스텝 체크는 영향 없음, 크래시 0).
- 가중 추첨/보유 다음레벨 가중(docs/03§2)은 앞에서 3개로 단순화 — 후속.

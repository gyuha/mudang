<!-- forge-slug: m7-meta-progress -->
# run — M7 영구메타 저장/해금 (계획 대비 실제)

실행: fg-loop 무인 드라이브(/goal). 직접 구현. 검증: 헤드리스 `meta_check`.

## 계획대로 된 것
- S1 MetaProgress(scripts/systems/meta_progress.gd): version/unlocked_stages/unlocked_companions/loadout_slots/meta_currency/meta_upgrades/stage_records/tutorial_done + save(user://save.json) + static load_or_new(없음/손상→기본값, version<CURRENT→_migrate).
- S2 record_clear(stage, time): stage_records cleared/best_time, 첫 클리어 first_clear_bonus 1회 + 매 클리어 meta_currency, stage/companion 해금.
- S3 RunScene: _result==win 1회 → load_or_new→record_clear(_stage,_run_time)→save (_meta_saved 가드).
- S4 meta_check 4종(기본값/정산/영속/migration) PASS.

## 검증 증거 (헤드리스)
- meta_check 4/4 PASS(기본 ver1/slots2/cur0 · 정산 150→200 첫보너스1회 · save→load 영속 · v0 migration 안전). 전 11종 회귀 green. main.tscn 300프레임 script error 0.

## 분기(divergence)
- **D-a. 메타 업그레이드 효과 적용 미구현(계획대로).** meta_upgrades 구조는 영속하나 효과(무녀/동료 시작 스탯 주입)는 런 주입 배선 필요 → 후속.
- **D-b. 패배 시 부분 재화 미적용.** docs/03§5 "런 실패→부분 메타재화"는 미구현 — 슬라이스는 승리 정산만. 후속 튜닝.
- **D-c. best_time = max(생존시간).** survive_time은 길수록 좋아 max로 기록(클리어는 ≈duration이라 사실상 고정값).

## 비고 — 헤드리스 검증 가능 로직 소진(최종)
- M3·M4·M5로직·M6·M7메타 = 헤드리스로 만들고 정합성 검증 가능한 backbone 전부 완료.
- 잔여는 전부 GUI/체감/실측/플레이테스트(human): M-S 500@60fps 렌더·FPS, M5-UI 3택/일시정지, M7 편성 화면, M8 HUD/미니맵/셰이더/밸런스, ★재미검증★. 자동 통과 불가.

<!-- forge-slug: shell-dashboard-stage-select -->
# run — 메타 셸 ①: 대시보드 + 스테이지 선택
fg-loop 드라이브 task 21. eco on. 워크플로우 없이 직접 실행.

## 계획대로
- S1 MetaProgress 로드 진입점: 기존 `MetaProgress.load_or_new()`(static, 저장 없으면 기본값=unlocked_stages 비어 1장만 해금) 그대로 활용 — 신규 코드 불필요.
- S2 `scripts/ui/dashboard.gd`(class_name Dashboard extends Control): 장 순서 6스테이지(STAGE_PATHS) 로드, `stage_entries()`로 {path,id,display_name,unlocked} 산출, `_build()`가 title_bg 배경 + 버튼 목록(잠긴 항목 disabled+🔒) 구성. unlock 판정 `_is_unlocked`: unlock_requires 비었거나 선행 스테이지 전부 unlocked_stages에 있으면 해금.
- S3 선택→전이: `select_stage(path)` 해금이면 `GameState.selected_stage_path` 설정 + `set_state(LOADOUT)` 후 true, 잠겼으면 false(전이 없음).

## 분기(divergence)
1. **.tscn 미생성(스타일 일치)**: 플랜은 dashboard.tscn 언급했으나 이 프로젝트 UI 관습은 코드 빌드 + `.new()` 인스턴스화(RunScene·LevelUpChoice 동일). 별도 .tscn 없이 class_name Dashboard로 작성 — main.gd가 상태별 `.new()`(task 23). 검증은 dashboard_check가 `Dashboard.new()`로 직접 인스턴스화. 의도(헤드리스 인스턴스+해금+전이) 충족.
2. 해금 사슬은 선형(각 장이 직전 장 클리어 요구): hwalinseo[] → musnyeo_village → mountain_pass → yangban_gut → seonsucheong → palace_wraith.

## 검증
- dashboard_check VERDICT => PASS: entries=6 · s1(hwalinseo) 해금 · s2(musnyeo_village) 잠김 · 잠금 선택 거부(state DASHBOARD 유지) · 해금 선택 시 selected_stage_path 설정 + state LOADOUT 전이.
- 전체 회귀 green 유지(다음 stop-condition 실행에서 확인).

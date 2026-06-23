<!-- forge-slug: stage2-village-content -->
<!-- task: 16 -->
<!-- tdd: off -->
# 스테이지 2 도성 밖 무녀촌 — 데이터 축 풀 구현 (docs/10 §6)
## Goal: 2장(필요시스템 없음=데이터 축만)을 완성. 다중 거점(3)+정적 화재 해저드+도깨비 테마+boss_dokkaebi_wrath. 스테이지 파라미터화.
## Non-goals: 시야제한/점거/다페이즈(예약, 3~6장), 편성/스테이지선택 UI(GUI).
## DoD: stage2_check PASS(validate/3거점/해저드/스폰/다중거점패배). 회귀 green, main 에러 0.
## Slices
- [x] HazardDef 스키마 + RunScene 적용
- [x] 다중 거점(defend_target 수만큼) + ObjectiveEval 다중(_min_stronghold_hp)
- [x] 스테이지 파라미터화(GameState.selected_stage_path) + 배경 stage id 기반
- [x] boss_dokkaebi_wrath EnemyDef+스프라이트, stage2.tres, 2장 배경/인트로 일러스트(codex-image)
- [x] stage2_check + 회귀

<!-- forge-slug: stage2-village-content -->
# run — 스테이지 2 무녀촌 (데이터 축)
fg-loop(/goal), eco on. codex-image(보스/배경/인트로 3) + 코드.
## 계획대로
- HazardDef(rect+dps+type, contains) + RunScene 구역 내 무녀/동료 dps.
- 다중 거점: defend_target 목표 수만큼 Stronghold 배치(STRONGHOLD_POSITIONS), ally_targets/접촉/결과 전부 배열화, _min_stronghold_hp(하나라도 0=패배).
- 스테이지 파라미터화: GameState.selected_stage_path(기본 1장), 배경 "bg/<id>.png" 폴백.
- boss_dokkaebi_wrath(HP800/resist0.85/sprite150) + stage_musnyeo_village.tres(survive420+거점3×200, 도깨비 테마, 화재존2, unlock_requires=1장, unlock=화랑).
## 검증
- stage2_check: validate/defend3/hazards2/strongholds3/스폰/다중거점-패배 PASS. 회귀 18종 green, main(1장) 에러 0.
- 시각(스프라이트/배경/해저드 존)은 GUI.
## 분기
- 데이터 축(D22 계층①)만으로 2장 완성 — docs/10 "2장 필요시스템 없음" 충족. 정적 해저드 시각 마커는 미표시(피해만; 마커는 후속).
- 단일→다중 거점 리팩터(내 변경) — stage1은 거점1로 동일 동작 유지.

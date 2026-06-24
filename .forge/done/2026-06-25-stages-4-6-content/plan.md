<!-- forge-slug: stages-4-6-content -->
<!-- task: 18 -->
<!-- tdd: off -->
<!-- generated-by: fg-loop -->
# 스테이지 4·5·6 계층① 데이터 저작 (C3 종결)

## Goal / Non-goals
- Goal: 4·5·6장을 계층① 데이터(목표·적테마·보스·정적 해저드)만으로 완성(docs/10 6.1 line 231·237 "계층①은 데이터만으로 완성"). StageDef .tres 3개 + boss_curse/boss_seal_wraith/boss_royal_wraith EnemyDef+스프라이트. validate+로드+승리경로 검증. → StageDef 2~6 전부 저작되어 C3 종결.
- Non-goals: 계층② 전용 엔진 3종(시야제한·점거게이지=purify_zone·다페이즈보스) — 예약 stub(데이터로만 존재, 평가 미구현). 특수 보스 거동(광역저주/소환/페이즈전환). 편성/스테이지선택/브리핑 UI(GUI). 밸런스(플레이테스트).

## Source of truth
- Glossary terms: StageDef, ObjectiveDef(kill_boss/purify_zone/survive_time), HazardDef, EnemyDef — .forge/CONTEXT.md
- Related ADRs: 데이터 주도 스테이지(D4/D14/D22), docs/10 §6·§7 + 6.1 계층표(line 231·237)
- Definition of Done: stage456_check PASS(각 stage validate 무에러 + 로드 + 승리경로: 4·5장 survive_time / 6장 kill_boss(boss_royal_wraith) 처치시 WIN) · 회귀 전 체크 green · main 파스·임포트 에러 0. StageDef 2~6 6개 모두 존재.

## Work slices
- [ ] S1. boss EnemyDef 3종 — boss_curse(저주 원귀), boss_seal_wraith(봉인 원귀), boss_royal_wraith(궁중 원귀). boss_dokkaebi_wrath/boss_tiger 참고한 탱키 스탯(신규 거동 없음, ai_kind=boss). — 완료기준: 로드 + 스폰 + (스프라이트는 S4)
- [ ] S2. 스테이지 4 양반가의 굿(stage_yangban_gut.tres) — objectives=[survive_time(420), purify_zone(예약 stub)], 탈귀(mask_spirit)+역병귀(plague) 테마, 독 장판 정적 해저드(poison), boss_curse 타임라인, unlock_requires=3장. — 완료기준: validate 무에러 + 로드, survive 승리경로
- [ ] S3. 스테이지 5 성수청 봉인(stage_seonsucheong.tres) — objectives=[survive_time, purify_zone×순차(예약 stub)], 혼합 테마(mob_low/ghost_maiden/mask_spirit/changgwi), 봉인진 정적 해저드, boss_seal_wraith 타임라인, unlock_requires=4장, unlock_companion=탈쓴퇴마사(있으면)/없으면 "". — 완료기준: validate 무에러 + 로드
- [ ] S4. 스테이지 6 궁궐 원귀 최종(stage_palace_wraith.tres) — objectives=[kill_boss(boss_royal_wraith), survive_time], 전 적종 테마, boss_royal_wraith 타임라인(다페이즈는 단일 kill_boss 예약), unlock_requires=5장. 보스 스프라이트 3종 codex-image(포그라운드 — 백그라운드 codex는 행). — 완료기준: validate + kill_boss 처치시 WIN + 스프라이트 임포트
- [ ] S5. stage456_check + 회귀 — 4·5·6 validate/로드/승리경로 + StageDef 2~6 6개 카운트. 기존 전 체크 green, main 에러 0. (depends: S1,S2,S3,S4)

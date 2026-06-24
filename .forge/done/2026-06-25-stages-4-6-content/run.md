<!-- forge-slug: stages-4-6-content -->
# run — 스테이지 4·5·6 계층① 데이터 저작 (C3 종결)
fg-loop replan round 2 fix-forward. eco on. 워크플로우 없이 직접 실행.

## 계획대로
- S1 boss EnemyDef 3종: boss_curse(HP760), boss_seal_wraith(HP820), boss_royal_wraith(HP1100, 최종). boss_tiger 패턴, ai_kind=boss, 신규 거동 없음.
- S2 4장 양반가의 굿(stage_yangban_gut): survive_time(420) + purify_zone(예약 stub), 탈귀(mask_spirit)+역병귀(plague), 독 장판 정적 해저드 2, boss_curse(t=240), unlock_requires=3장.
- S3 5장 성수청 봉인(stage_seonsucheong): survive_time(450) + purify_zone×3 순차(예약 stub), 혼합 테마 4종, 봉인진 해저드, boss_seal_wraith(t=300), unlock_requires=4장.
- S4 6장 궁궐 원귀 최종(stage_palace_wraith): kill_boss(boss_royal_wraith) + survive_time, 전 적종 6+보스, 호드 러시(t=200)+보스(t=260), 복합 해저드 2, unlock_requires=5장. 보스 3종 스프라이트 codex-image(포그라운드).
- S5 stage456_check + 회귀: 4·5·6 validate/로드/승리경로(6장 kill_boss 처치시 WIN) + StageDef 1~6 6/6 PASS. 회귀 20종 green, main 파스·임포트 에러 0.

## 분기(divergence)
1. **판단 갱신(이전 reflection 반전)**: 이전엔 4~6장을 '예약 엔진 선행/fork'로 봤으나 docs/10 6.1 line 231·237("각 시스템 만들어지기 전에도 계층①만으로 성립", "계층①은 데이터만으로 완성 D4")이 결정적 → 승인 스코프 내 빌드 확정. 4·5장은 survive_time이 승리경로(purify_zone 평가는 예약), 6장은 kill_boss가 승리경로(다페이즈는 단일 보스 예약).
2. **codex-image는 포그라운드만 동작**: 백그라운드/함수래퍼+timeout 조합은 행/실패(boss_curse만 1차 성공). 보스별 단일 포그라운드 codex exec로 안정 생성(seal_wraith/royal_wraith).
3. **계층② 예약 stub**: purify_zone(점거게이지)·다페이즈·시야제한(global_rule null)은 데이터로만 존재, 평가 엔진 미구현 — docs가 별도 엔지니어링 일감으로 스케줄. 특수 보스 거동(광역저주/소환/페이즈)도 미구현(기본 boss 이동).
4. **탈쓴퇴마사 동료 미존재**: 5장 unlock_companion="" (companion .tres 3종만 존재, docs D26 배치 미정).
5. **스테이지 배경/인트로 일러스트 미생성**(eco): 배경 폴백, 인트로 텍스트 카드. 보스 스프라이트만 생성. → 아트 후속.

## 검증
- stage456_check: s4(validate/survive/purify/hazards2) · s5(validate/purify_seq3) · s6(validate/kill_boss=boss_royal_wraith) · s6 run(보스추적/생존중NONE/처치시WIN) · StageDef 1~6 6/6 전부 PASS.
- 회귀 20종 green + move 진단(dx=110) · main 파스·임포트 에러 0 · 보스 3종 스프라이트 임포트 OK.

<!-- forge-slug: stage3-killboss-tiger -->
<!-- task: 17 -->
<!-- tdd: off -->
<!-- generated-by: fg-loop -->
# 스테이지 3 — kill_boss 목표 평가 + 호랑이 보스 (데이터 축, C2 완결 + C3 전진)

## Goal / Non-goals
- Goal: kill_boss 목표를 ObjectiveEval에서 실제 평가(대상 보스 사망=승리)하고, 이를 사용하는 3장(boss_tiger + 도깨비/잡귀 테마 + 정적 해저드 재사용)을 데이터 축으로 저작·검증. C2(kill_boss 지원) 완전 충족, C3(StageDef 2~6) 전진.
- Non-goals: 시야제한(예약 stub — 연출용, 없어도 플레이 성립), purify_zone/다페이즈(4~6장), 편성/스테이지선택 UI(GUI), 3장 배경/인트로 일러스트(eco — 폴백 사용, 아트 후속).

## Source of truth
- Glossary terms: kill_boss, ObjectiveDef, ObjectiveEval, HazardDef, StageDef — .forge/CONTEXT.md
- Related ADRs: 데이터 주도 스테이지 저작(D14/D22, docs/04 §3 · docs/10 §6)
- Definition of Done: stage3_check PASS(stage3.tres validate + kill_boss 보스 사망 시 WIN 판정 + 보스 생존 중 NONE) · 회귀 전 체크 green · main(1장) import 파스 에러 0.

## Work slices
- [ ] S1. ObjectiveEval에 kill_boss 평가 추가 — objectives 배열에 kind=kill_boss가 있으면, 해당 enemy_id 보스가 사망해야 WIN(survive_time 미사용 가능). 보스 생존 추적은 RunScene이 EnemySystem `_kill` 훅(또는 on_kill)에서 대상 id 사망을 감지해 플래그로 evaluate에 전달. — 완료기준: 보스 살아있으면 NONE, 사망하면 WIN(헤드리스 단위 검증)
- [ ] S2. boss_tiger EnemyDef(.tres) — boss_dokkaebi_wrath 참고한 탱키 스탯, 신규 거동 없음(기본 이동). 스프라이트 1장 codex-image(로스터 시각 정합성). — 완료기준: 로드 + EnemySystem 스폰 + 스프라이트 적용 (sprite_check/roster 패턴)
- [ ] S3. stage_*_3.tres 저작 — objectives=[kill_boss(boss_tiger)], 도깨비/잡귀 테마 spawn_pool, 보스 timeline 등장, 정적 화재 해저드 재사용, unlock_requires=2장. — 완료기준: StageDef.validate() 무에러 + 로드
- [ ] S4. stage3_check + 회귀 — kill_boss WIN/NONE 분기 + validate + 스폰. 기존 전 체크 green, main 에러 0. (depends: S1,S2,S3)

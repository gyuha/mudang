<!-- forge-slug: enemy-ai-kinds -->
<!-- task: 24 -->
<!-- tdd: off -->
<!-- priority: high -->
<!-- generated-by: fg-loop -->
# 적 AI 거동 분화 — enemy_system이 ai_kind를 실제 사용 (타겟/이동)

## Goal / Non-goals
- Goal: `EnemySystem._nearest_target`(현재 전 적 "최근접 아군" 단일)을 `EnemyDef.ai_kind`별로 분기한다. rush_companion(기본, 최근접 아군=동료/거점), target_companion(동료만 — 거점 더 가까워도 무시), rush_lowhp(최저 HP 동료 추적), elite/boss(이동은 rush_companion과 동일하되 분기 존재). 데이터의 ai_kind 값(이미 세팅됨)이 거동에 반영되게 한다.
- Non-goals: ranged 원거리 공격(task 25 별도), 보스 특수 패턴/페이즈(계층② 후속), elite의 특수 거동(현재 데이터상 rush와 동일 이동), 적 투사체.

## Source of truth
- Glossary terms: ai_kind, rush_companion/target_companion/rush_lowhp in .forge/CONTEXT.md
- Related ADRs: docs/04 §1(ai_kind 거동), docs/02 §2(타게팅), docs/11 §1(EnemySystem API)
- Definition of Done: enemy_ai_kind_check가 `VERDICT => PASS` — rush_lowhp/target_companion/rush_companion이 서로 다른 타겟을 향함이 확인되고, 기존 회귀 green 유지.

## 설계 메모
- ally_targets에는 동료(Companion)와 거점(Stronghold)이 섞여 있다. 동료/거점 구분 필요 — Companion은 `is_incapacitated()`/`hp` 등 메서드 보유, 거점은 아님. 타입 또는 has_method으로 동료 판별(예: `has_method("is_downed")` 또는 그룹). 최소 침습: 동료만 거를 수 있는 판별자 사용.
- rush_lowhp: 동료 중 현재 HP 최소(전투가능)인 대상. HP 접근은 Companion의 공개 getter 필요(없으면 추가).
- `_nearest_target(from, def)`로 시그니처에 def(또는 ai_kind) 전달. tick 루프에서 `_def[i]` 넘김.
- 기존 도발(taunt) 오버라이드는 rush 계열에 한해 유지(현 동작 보존).

## Work slices
- [ ] S1. tools/test/enemy_ai_kind_check.gd+.tscn(먼저) — 완료 기준: 동료 2인(가까운 고HP + 먼 저HP) + 거점 1을 배치하고 ai_kind별 적 1마리씩 스폰 후 tick → rush_lowhp는 저HP 동료 방향, target_companion은 동료 방향(거점 더 가까워도), rush_companion은 최근접 아군 방향으로 이동함을 검증. 현재 코드(미분기)에선 FAIL.
- [ ] S2. EnemySystem ai_kind 분기 구현 — 완료 기준: `_nearest_target`이 ai_kind를 받아 분기(동료 필터/최저HP/최근접). 공개 API 시그니처는 외부에서 보던 것 유지(내부 tick 호출만 def 전달). enemy_ai_kind_check PASS.
- [ ] S3. 회귀 무파손 — 완료 기준: 기존 tools/test/*_check 전부 green(companion_ai/wave_objective/stage* 등), main 부팅 에러 0.

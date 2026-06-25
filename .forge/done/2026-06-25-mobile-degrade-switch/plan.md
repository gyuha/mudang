<!-- forge-slug: mobile-degrade-switch -->
<!-- task: 30 -->
<!-- tdd: off -->
<!-- priority: medium -->
<!-- generated-by: fg-loop -->
# 모바일 열화 스위치 — 동시 적 상한 동적 하향 (250)

## Goal / Non-goals
- Goal: 저사양/모바일 열화 토글을 두고, 켜지면 동시 적 상한을 250(모바일 목표, docs/06)으로 하향한다. EnemySystem이 동적 상한(active_limit)을 갖고, 전역 플래그가 이를 구동한다. PC(off)=500+, 모바일(on)=250.
- Non-goals: 파티클 밀도/그림자/해상도 스케일 열화(파티클·포스트 효과 미존재 — 후속), 설정 화면 UI(별도), 플랫폼 자동 감지(수동 플래그로 충분), 저장 영속.

## Source of truth
- Glossary terms: 모바일 열화, active_limit in .forge/CONTEXT.md
- Related ADRs: docs/06(모바일 250·열화 노브), docs/07 M-S(250 모바일)
- Definition of Done: mobile_degrade_check가 `VERDICT => PASS` — 열화 플래그 ON 시 spawn이 250에서 클램프(active_count ≤ 250), OFF 시 500+ 가능. 플래그가 EnemySystem.active_limit에 반영. 회귀 무파손.

## 설계 메모
- EnemySystem에 `var active_limit: int = CAP` 추가. spawn 클램프를 `_count >= min(CAP, active_limit)`로 변경.
- 전역 플래그: GameState에 `low_spec: bool = false`. RunScene._ready에서 `_enemies.active_limit = 250 if GameState.low_spec else EnemySystem.CAP`. (향후 파티클/품질도 이 플래그로 분기 — 자리만)
- 토글 진입점: GameState.low_spec를 세팅하는 단순 함수/직접 대입(설정 화면 UI는 Non-goal). 검증은 플래그 토글 → RunScene 적용 또는 active_limit 직접 확인.

## Work slices
- [ ] S1. tools/test/mobile_degrade_check.gd+.tscn(먼저): (1) es.active_limit=250 후 300마리 spawn → active_count==250. (2) GameState.low_spec=true로 RunScene 인스턴스 → _enemies.active_limit==250. low_spec=false → ==CAP. 미구현 시 FAIL.
- [ ] S2. EnemySystem active_limit 필드 + spawn 클램프 min(CAP, active_limit).
- [ ] S3. GameState.low_spec + RunScene._ready에서 active_limit 적용. mobile_degrade_check PASS.
- [ ] S4. 회귀 무파손: 기존 체크 green(특히 enemy_pool_check CAP 동적·perf500 500), main 부팅 0.

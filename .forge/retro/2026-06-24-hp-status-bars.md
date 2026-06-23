# 2026-06-24 — HP 스테이터스 바 (무녀·동료 머리 위 체력 바)

## Plan vs actual
- What went as planned: 4슬라이스 전부 계획대로. `HpBar`(코드 _draw) + 무녀/동료 _ready 자식 부착 + RunScene _process 갱신 + hp_bar_check 4종. 분기 없음. 직접 구현(소규모).
- Divergences: 없음.

## Learnings
- Do differently next time:
  - (재확인, 신규 아님) **HUD/시각 작업은 헤드리스로 로직·바인딩까지만 검증 가능** — 실제 모양/위치/색은 GUI 확인이 게이트. `HpBar.fill_width()`/`fill_color()`를 순수 함수로 빼 수학·색 경계를 헤드리스 단언한 패턴은 다른 HUD(거점 바, EXP/쿨 게이지, 미니맵 M8)에도 그대로 재사용할 것.
  - 액터 _ready에 시각 자식(HpBar) 추가는 기존 헤드리스 체크에 무영향(12종 green) — 시각 노드를 step/tick 밖 _process로 갱신해 결정성 분리한 것이 안전했다.

## Doc updates
- CONTEXT.md promotion: none (도메인 용어 아님 — HpBar는 구현 디테일).
- ADR added: none (되돌리기 어려운 결정·트레이드오프 아님).
- 기타: HUD 시각 검증 경계는 m0 회고(헤드리스로 시각 못 닫음)의 재확인 — 영구 귀속처는 그 회고 + 이 로그. 거점 HP 바는 같은 HpBar로 후속 1줄 추가 가능(이번 Non-goal).

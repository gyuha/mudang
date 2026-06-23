<!-- forge-slug: art-unit-sprites -->
<!-- task: 10 -->
<!-- tdd: off -->
# 유닛 스프라이트 아트 — 무녀·동료 ColorRect → 생성 스프라이트

## Goal / Non-goals
- Goal: codex-image로 무녀+동료3 투명 스프라이트 생성 → 액터 ColorRect 플레이스홀더를 Sprite2D로 교체. (docs/08 아트 방향)
- Non-goals: 8방향/프레임 애니(AnimatedSprite — 후속), 적/보스/배경(다음 작업), 시각 품질 튜닝(GUI/사용자).

## Source of truth
- docs/08 §1·§2 아트 방향. 헤드리스 검증 = 텍스처 로드/스프라이트 부착.
- Definition of Done: assets/sprites/{mudang,hwarang,hwaljabi,gyeonseup}.png 투명 PNG 존재 + sprite_check PASS + 회귀 green.

## Work slices
- [x] S1. codex-image로 투명 스프라이트 4종 생성 → assets/sprites/ — RGBA 투명 확인
- [x] S2. mudang.gd/companion.gd: Sprite2D(텍스처) 교체 + 누락 시 ColorRect 폴백, HpBar Y오프셋 상향 — sprite_check PASS

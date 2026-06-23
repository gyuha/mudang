<!-- forge-slug: art-unit-sprites -->
# run — 유닛 스프라이트 아트

실행: fg-loop 드라이브(/goal), eco on. codex-image(codex exec, 투명 모드)로 생성 + 직접 와이어링.

## 계획대로
- S1 무녀+동료3 투명 RGBA 1024² 스프라이트 생성(assets/sprites/).
- S2 mudang/companion _ready: Sprite2D(SPRITE_SIZE 64로 축소) 교체, 텍스처 누락 시 ColorRect 폴백. HpBar Y_OFFSET -20→-42(스프라이트 위 클리어).

## 검증
- sprite_check: 무녀+동료3 전부 Sprite2D+텍스처 사용(폴백 아님) PASS. 회귀 10종 green, main 150프레임 에러 0, import 파스 에러 0.
- 시각 적합성(스프라이트 모양/스케일/방향)은 GUI 확인 몫.

## 분기
- AnimatedSprite(8방향/프레임)는 단일 Sprite2D로 축소(docs/08은 AnimatedSprite 권장) — 슬라이스는 정지 스프라이트로 충분, 애니는 후속.
- 원본 1024²를 런타임 scale 축소(import 리사이즈 아님) — 단순/충분, 메모리 최적화는 후속.

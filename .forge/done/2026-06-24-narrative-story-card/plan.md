<!-- forge-slug: narrative-story-card -->
<!-- task: 14 -->
<!-- tdd: off -->
# 서사 카드 — 장 시작 일러스트+텍스트 (D23)

## Goal / Non-goals (docs/11 §5, D23)
- Goal: codex-image로 1장 인트로 일러스트 생성 + StageDef 데이터(intro_image_path/intro_text)로 장 시작 미니멀 카드(일시정지) → 닫으면 런 시작.
- Non-goals: 장 끝(outro) 카드·VN/컷신(후속), 시각 체감(GUI).

## Definition of Done
- story_card_check PASS(StageDef intro 필드 + show_card 텍스트 분기/라벨). 회귀 green, main 에러 0.

## Work slices
- [x] S1. codex-image 인트로 일러스트(assets/story/ch1_intro.png)
- [x] S2. StageDef intro_image_path/intro_text + stage_hwalinseo.tres
- [x] S3. StoryCard(CanvasLayer, 일시정지+일러스트+텍스트+딕미스) + RunScene 배선 + story_card_check

<!-- forge-slug: narrative-story-card -->
# run — 서사 카드

실행: fg-loop(/goal), eco on. codex-image + 직접 구현.

## 계획대로
- 인트로 일러스트 1536x1024 생성.
- StageDef.intro_image_path/intro_text(@export_multiline) + stage_hwalinseo.tres에 1장 텍스트.
- StoryCard: show_card(빈 텍스트면 false), 암전+일러스트(TextureRect)+텍스트(autowrap)+버튼, 일시정지/딕미스(PROCESS_MODE_ALWAYS).
- RunScene _ready 끝에서 표시.

## 검증
- story_card_check: data_ok/empty_no/shown/has_text PASS. 회귀 14종 green, main 150프레임 에러 0.
- 카드 렌더/딕미스 체감은 GUI. main 헤드리스는 인트로에서 일시정지(수동 스텝 체크 영향 없음, 크래시 0).

## 분기
- 장 끝 카드/VN은 후속(슬라이스는 인트로만). load 삼항을 if로 분리(파스 안정).

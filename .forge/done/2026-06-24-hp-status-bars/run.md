<!-- forge-slug: hp-status-bars -->
# run — HP 스테이터스 바 (계획 대비 실제)

실행: 직접 구현(소규모 결합 UI). 검증: 헤드리스 `hp_bar_check`(로직/바인딩) + 시각은 GUI 몫.

## 계획대로 된 것
- S1 `HpBar`(scripts/ui/hp_bar.gd, Node2D): set_ratio(클램프+queue_redraw)/fill_width(순수)/fill_color(녹↔적 lerp, 전투불능 회색)/_draw(배경+채움), Y_OFFSET로 머리 위.
- S2 Mudang: _ready에 HpBar 자식 + refresh_hp_bar()(hp/MAX_HP).
- S2b Companion: _ready에 HpBar 자식 + refresh_hp_bar()(hp/def.max_hp, is_incapacitated→회색).
- S3 RunScene._process: 매 프레임 무녀+동료 refresh_hp_bar().
- S4 hp_bar_check 4종(수학/색/무녀바인딩/동료바인딩+회색) PASS.

## 검증 증거
- hp_bar_check 4/4 PASS. 전 12종 회귀 green(HpBar 자식 추가가 기존 체크 무영향). main.tscn 200프레임 script error 0.
- **시각(머리 위 바 모양/위치/색)은 헤드리스 불가 → 사용자가 main.tscn에서 확인 필요.**

## 분기(divergence)
- 없음(계획대로). 거점 바는 계획대로 제외(요청 범위 밖). DOWNED/LOST 회색·항상 표시 사용자 결정 반영.
- 만피 숨김 안 함(항상 표시) — 사용자 선택.

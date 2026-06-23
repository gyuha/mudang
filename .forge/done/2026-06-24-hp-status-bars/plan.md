<!-- forge-slug: hp-status-bars -->
<!-- task: 9 -->
<!-- priority: medium -->
<!-- tdd: off -->
# HP 스테이터스 바 — 무녀·동료 머리 위 체력 바 (HUD 슬라이스)

## Goal / Non-goals
- Goal: 무녀와 동료 3인의 **머리 위 월드 공간 HP 바**를 표시한다(항상 표시). 재사용 `HpBar`(코드 `_draw`)가 `hp/max` 비율로 채워지고 비율에 따라 녹→적, 전투불능(DOWNED/LOST) 동료는 회색. 가독성용 HUD 슬라이스. (docs/08 §3·§5)
- Non-goals (별도/후속):
  - **거점(병자 거점) HP 바** — 요청 범위 밖(같은 HpBar로 후속 1줄 추가 가능)
  - 화면 고정 HUD 패널·미니맵·EXP/쿨다운 게이지 — M8
  - 부활 게이지 전환 연출·데미지 숫자·셰이더/애니 — M8
  - 만피 시 숨김(사용자가 "항상 표시" 선택)

## Source of truth
- Glossary terms: 동료=Companion("무사"는 구어), 무녀=Mudang (docs/00 §3). `.forge/CONTEXT.md` 미생성.
- Related ADRs: none(신규 결정 없음 — 기존 가독성 방향 docs/08 §3 따름).
- Definition of Done: `tools/test/hp_bar_check` 헤드리스 PASS — (1) HpBar 비율→fill 폭/클램프/색(녹↔적) 정확, (2) 무녀·동료 refresh 시 바 비율이 hp/max와 일치, (3) DOWNED/LOST 동료 바 회색. M1~M7 회귀 정상. **시각적 모양/위치는 사용자가 `main.tscn`에서 확인(GUI — 헤드리스 불가).**

## Work slices
- [ ] S1. `HpBar`(`scripts/ui/hp_bar.gd`, Node2D): `set_ratio(r)`(0~1 클램프+queue_redraw), `fill_width()`(=BAR_W*ratio, 순수), `incapacitated` 플래그, `_draw`(배경 어두운 rect + fill rect; 색=ratio로 녹↔적 lerp, incapacitated면 회색). 유닛 위 Y오프셋. — completion criterion: set_ratio 클램프/fill_width/색 경계(ratio 1=녹, 0=적, incap=회색)가 헤드리스 단언 통과
- [ ] S2. 무녀 바인딩: `Mudang`이 `_ready`에서 HpBar 자식 생성(`var hp_bar`), `refresh_hp_bar()`로 `hp/MAX_HP` 반영 — completion criterion: hp 50/100 → hp_bar.ratio==0.5 (헤드리스 PASS) (depends: S1)
- [ ] S2b. 동료 바인딩: `Companion`이 `_ready`에서 HpBar 자식 생성, `refresh_hp_bar()`로 `hp/def.max_hp` 반영 + DOWNED/LOST면 incapacitated=true(회색) — completion criterion: 부상 동료 ratio 일치, 쓰러진 동료 바 회색(헤드리스 PASS) (depends: S1)
- [ ] S3. RunScene 구동: `_process`에서 매 프레임 무녀+동료 `refresh_hp_bar()` 호출(틱 소유 일관) — completion criterion: 런에서 각 유닛 머리 위 바가 hp에 따라 갱신(통합; 시각은 GUI 확인) (depends: S2, S2b)
- [ ] S4. 헤드리스 체크 `tools/test/hp_bar_check.*`(HpBar 수학/색 + 무녀·동료 바인딩 + 회색) + import 선행 + M1~M7 회귀 — completion criterion: `godot --headless` 전 체크 PASS, 회귀 정상 (depends: S3)

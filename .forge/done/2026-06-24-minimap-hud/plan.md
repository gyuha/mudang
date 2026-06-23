<!-- forge-slug: minimap-hud -->
<!-- task: 13 -->
<!-- tdd: off -->
# 미니맵 HUD — 무녀/동료/거점/보스 마커 + 쓰러짐 표시

## Goal / Non-goals (docs/08 §6)
- Goal: 우상단 미니맵 — world→minimap 변환, 무녀/동료(역할색,쓰러짐=적)/거점(HP색)/보스·엘리트 마커. 정보 전용.
- Non-goals: 화면 밖 화살표 클램프·핑 SFX·잡몹 밀도 음영(후속/M8), 시각 체감(GUI).

## Definition of Done
- minimap_check PASS(world_to_mini 코너/중심 정확). 회귀 green, main 에러 0.

## Work slices
- [x] S1. MinimapHUD(Control): world_to_mini 순수함수 + _draw(프레임/거점/보스엘리트/동료/무녀)
- [x] S2. RunScene 배선(refs) + minimap_check

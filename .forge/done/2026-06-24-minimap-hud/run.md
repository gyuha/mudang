<!-- forge-slug: minimap-hud -->
# run — 미니맵 HUD

실행: fg-loop(/goal), eco on. 직접 구현.

## 계획대로
- MinimapHUD(Control, 우상단 앵커): world_to_mini((w+H)/(2H)*S) 순수함수, _draw로 프레임+거점(HP색)+보스/엘리트(sprite_size≥60만, 잡귀 개별점 금지 §6.2)+동료(역할색/쓰러짐 적색 §6.3)+무녀.
- RunScene ui_layer에 추가 + refs(mudang/companions/stronghold/enemies).

## 검증
- minimap_check: 코너(-H,-H)→(0,0), (H,H)→(S,S), 0→(S/2,S/2) PASS. 회귀 14종 green, main 200프레임 에러 0.
- 마커 렌더/배치 체감은 GUI.

## 분기
- 화면 밖 화살표·핑·밀도 음영은 docs §6 권장이나 후속(슬라이스는 마커까지). 보스/엘리트 판정에 sprite_size 재사용.

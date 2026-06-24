<!-- forge-slug: art-assets-codex-image -->
# run — 아트 에셋 완비: 스테이지 3~6 배경 + 타이틀 (codex-image)
fg-loop 드라이브 task 19 (첫 작업). eco on. 워크플로우 없이 직접 실행(codex-image는 메인 세션 포그라운드 단일 호출만 안정 — 직전 드라이브 학습).

## 계획대로
- S1 스테이지 3·4·5·6 배경 4종 codex-image 생성(1024×1024, 기존 배경과 동일 사양·탑다운 전장 맵 스타일): stage_mountain_pass(안개 산길+청록 혼불), stage_yangban_gut(양반가 굿판 마당+독기), stage_seonsucheong(관아 봉인진+청광), stage_palace_wraith(궁궐 광장+혈홍/금 원귀 기운).
- S2 title_bg 1종 codex-image 생성(혈월 아래 무녀 실루엣 키 비주얼, 하단 어둠으로 UI 여백, quality high).
- S3 godot --headless --import 반영 → 신규 png 5종 .import 생성, main.tscn 부팅 시 누락 리소스 ERROR 0.
- S4 tools/test/art_assets_check.gd+.tscn 작성 → 6스테이지 bg + title_bg + 12 EnemyDef + 3 CompanionDef 참조 스프라이트 전수 ResourceLoader.exists 확인.

## 분기(divergence)
1. **codex exec 2분 타임아웃 1회**: 첫 mountain_pass 시도가 reasoning_effort=medium + 2분 제한에서 미완. reasoning_effort=low + 5분 타임아웃으로 전환해 5종 전부 안정 생성. → 다음 이미지 작업도 low effort/5분 권장.
2. **배경은 탑다운 전장 맵, 타이틀만 풍경 키 비주얼**: 기존 stage_hwalinseo(돌바닥)·stage_musnyeo_village(마을 조감) 확인 후 스테이지 배경은 조감 맵으로, title_bg만 포스터형으로 분리 제작.

## 검증
- art_assets_check VERDICT => PASS: stage bg 6/6 · title_bg=true · enemy sprites 12/12 · companion sprites 3/3.
- main.tscn 헤드리스 부팅(3프레임) — not found/SCRIPT ERROR/Parse Error 0건.
- stage456_check VERDICT => PASS(이전 stage_palace_wraith.png 누락 ERROR 해소).

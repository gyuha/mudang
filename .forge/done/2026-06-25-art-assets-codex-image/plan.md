<!-- forge-slug: art-assets-codex-image -->
<!-- task: 19 -->
<!-- tdd: off -->
<!-- priority: high -->
<!-- generated-by: fg-loop -->
# 아트 에셋 완비 — 스테이지 3~6 배경 + 타이틀/대시보드 아트 (codex-image)

## Goal / Non-goals
- Goal: 누락된 게임 아트를 codex-image 스킬로 제작·임포트해 C5(아트 완비)와 C2(리소스 에러 0)를 통과시킨다. (1) 스테이지 3·4·5·6 배경 `assets/bg/<stage.id>.png` (run_scene.gd:73 규약), (2) 타이틀/대시보드용 배경 1종, (3) 검증 체크 `art_assets_check.tscn` 작성.
- Non-goals: 스프라이트 재제작(이미 완비), 스테이지 1·2 배경(이미 존재), 셸 UI 레이아웃(task 21~23), 오디오.

## Source of truth
- Glossary terms: 계층① 아트, StageDef.id in .forge/CONTEXT.md (기존 등재면 그대로)
- Related ADRs: none (아트 추가는 데이터 추가)
- Definition of Done: `assets/bg/`에 6스테이지 배경 전부 존재 + 타이틀 아트 존재 + `art_assets_check.tscn`이 `VERDICT => PASS`, `main.tscn` 부팅 시 누락 리소스 ERROR 0.

## 배경 대상 (stage.id ↔ 테마, docs/10 + DESIGN 참조)
- stage_mountain_pass (3장 산길의 창귀) — 안개 낀 조선 산길, 밤, 호랑이 창귀 보스 테마
- stage_yangban_gut (4장 양반가 굿) — 조선 양반가 기와집 마당, 굿판, 독기(해저드) 분위기
- stage_seonsucheong (5장 선수청) — 관아/선수청 내부, 봉인 정화 의식
- stage_palace_wraith (6장 궁궐 원귀) — 조선 궁궐 야경, 왕실 원귀(royal_wraith) 보스 테마
- title_bg (타이틀/대시보드) — 무녀 키 비주얼풍 야경 포스터 (기존 concept-title-poster 톤 참조)

> 스타일 통일: 기존 `assets/bg/stage_hwalinseo.png`·`stage_musnyeo_village.png`의 톤(조선 시대, 어두운 밤, 가로 배경)과 맞춘다. 해상도는 기존 배경과 동일 비율.

## Work slices
- [ ] S1. 스테이지 3·4·5·6 배경 4종을 codex-image로 제작 — 완료 기준: `assets/bg/stage_mountain_pass.png`, `stage_yangban_gut.png`, `stage_seonsucheong.png`, `stage_palace_wraith.png` 4개 파일이 프로젝트에 존재(.import 동반).
- [ ] S2. 타이틀/대시보드 배경 1종 codex-image 제작 — 완료 기준: `assets/bg/title_bg.png` 존재(.import 동반).
- [ ] S3. Godot 임포트 반영 — 완료 기준: `godot --headless --path . --import` 후 새 png 5종에 `.import` 생성, `main.tscn` 부팅 시 `not found` ERROR 0건. (depends: S1, S2)
- [ ] S4. `tools/test/art_assets_check.gd` + `.tscn` 작성 — 완료 기준: 6스테이지 bg(`assets/bg/<id>.png`) + `title_bg.png` + 6 StageDef·3 CompanionDef·전체 EnemyDef가 참조하는 텍스처를 `ResourceLoader.exists`로 전수 확인하고 `VERDICT => PASS` 출력, headless 실행 시 PASS. (depends: S3)

# run.md — M0 프로젝트 골격 + 성능 스파이크 + 무녀 이동

실행: 2026-06-21 · 단일 구현 에이전트(워크플로우 미사용 — 규모 작음, fg-run "small → direct" 지침)

## 계획대로 된 것
- **S1** GameState autoload(enum S + state + state_changed) + Main→RunScene 코드 로드. `project.godot`에 autoload·`run/main_scene` 등록. (`scripts/autoload/game_state.gd`, `scripts/main.gd`, `scripts/run_scene.gd`)
- **S2** InputAdapter 3종 입력(`move_vector` WASD / `aim_point`+`aim_pressed` / `rally_pressed`) + RunScene 디버그 라벨 실시간 표시. `[input]` 맵(WASD/LMB/Space+RMB) 등록. (`scripts/autoload/input_adapter.gd`)
- **S3** Mudang 220px/s 이동(`_physics_process`) + 자식 Camera2D 추적, ColorRect 플레이스홀더. (`scripts/actors/mudang.gd`)
- **S4** 던지는 성능 스파이크 — 별도 씬(게임 미연동), 500더미 1 MultiMeshInstance2D 드로우 + 매 프레임 균일격자 spatial hash 재구축/query_circle, FPS 라벨. (`tools/bench/bench_500.{gd,tscn}`)

## 계획 대비 divergence (낮음)
- InputAdapter를 **autoload로 확정**(계획은 "autoload 또는 노드" 허용 — 선택지 내).
- 파일을 `scripts/autoload/`·`scripts/actors/`·`scenes/`·`tools/bench/`로 배치(STRUCTURE 컨벤션 따름). 계획에 명시 없던 정리.
- `[input]` 액션 맵 등록은 계획에 없었으나 즉시 동작에 필요해 추가(WASD/aim/rally).
- 기존 데이터 레이어(`scripts/data/*.gd`, `data/**`, `tools/seed_stage1.gd`) **무손상** 확인.

## 막힌 곳 / 미해결 (Godot 미실행 — 사람 검증 필요)
1. `aim_point`: `cam.get_global_mouse_position()`(+뷰포트 폴백) — 카메라 하 좌표 정확성 에디터 확인 필요. `# NOTE` 표기됨.
2. MultiMesh 더미가 무텍스처 흰 QuadMesh — 실제 가시성 에디터 확인 필요. `# NOTE` 표기됨.
3. autoload명 vs `class_name` 충돌 회피로 GameState/InputAdapter는 `class_name` 미선언 — "hides autoload" 경고 없는지 확인. `[Medium]` 관용구 확신.
4. `main.tscn` ext_resource `uid` 없음 — Godot가 임포트 시 재생성. `[High]` 무해.

## 검증 사이클 (verification-only resume + fix-and-re-run)
1. **기계 검증(헤드리스):** `godot --headless` main 씬 부팅 exit 0·에러 0, `bench_500.tscn` 부팅 exit 0·에러 0. autoload·RunScene·Mudang·Camera·라벨·스파이크 전부 크래시 없이 로드. autoload-vs-class_name "hides autoload" 경고 없음.
2. **UAT 1차(사람):** "가운데 네모만, 움직이는지 모르겠다." → S3 "WASD 이동" 관측 불가.
3. **진단:** 헤드리스 이동 테스트(`tools/test/move_check`) → `dx=110.00`(=220×0.5, 기대치 일치). **이동 로직은 정상.** 원인은 *카메라가 무녀 자식 + 빈 월드* → 박스가 화면 중앙 고정처럼 보임(관측 불가).
4. **수정(fix-forward, S3 관측성):** 월드 고정 `BgGrid`(`scripts/bg_grid.gd`)를 RunScene 첫 자식으로 추가(이동이 그리드 대비 보임) + 디버그 라벨에 무녀 `global_position` 표시. → 헤드리스 재부팅 clean(에러 0).

## 추가 divergence / gotcha
- 새 `class_name`(BgGrid) 추가 후 헤드리스 실행 전 **`godot --headless --import` 필수**(전역 클래스 캐시 갱신). 안 하면 "Identifier ... not declared" 파스 에러. → CONCERNS/CONVENTIONS 반영 후보.
- `tools/test/move_check.{gd,tscn}` = 던지는 검증 코드(이동 로직 확인용). 보존 또는 정리 택.

## 검증 상태
- **S1·S2 (로드/파스/autoload):** 기계 확인 ✓ (헤드리스 부팅 clean)
- **S3 (WASD 이동·카메라):** 이동 로직 기계 증명 ✓ (`dx=110.00`), 관측성 수정 적용 ✓. **시각 재확인만 GUI 필요**(이제 그리드 대비 박스 이동 보여야 함).
- **S4 (500@60fps):** 스파이크 씬 로드 ✓, **FPS 수치는 GUI 실측 필요**(헤드리스 무의미).

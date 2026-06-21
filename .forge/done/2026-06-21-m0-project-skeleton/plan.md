<!-- forge-slug: m0-project-skeleton -->
<!-- task: 1 -->
<!-- tdd: off -->
# M0 — 프로젝트 골격 + 성능 스파이크 + 무녀 이동

## Goal / Non-goals
- Goal: Godot 4 프로젝트의 실행 골격(RunScene·GameState·InputAdapter·Camera)을 세우고, 무녀가 WASD로 움직이며 카메라가 따라오게 한다. 더불어 **던지는 성능 스파이크**로 "500마리 MultiMesh + spatial hash 이동 = 60fps"라는 렌더 접근법([06]/D19)을 *재미 검증 전에* 싸게 확인한다([07] M0).
- Non-goals: 적·동료·전투·혼불·케어·UI·스테이지 데이터(.tres) 연동·셰이더 애니·모바일 입력 — 전부 M1 이후. 성능 스파이크는 **본 게임에 통합하지 않는다**(별도 씬, 검증 후 보존만).

## Source of truth
- 설계 권위(이 프로젝트는 `docs/`가 출처): `docs/01-코어루프-무녀.md`(§1 입력 추상 레이어·§7 무녀 기본 수치 이동 220), `docs/06-기술아키텍처.md`(§1 MultiMesh·§2 SpatialHash·§3 씬 트리·§5 성능 예산), `docs/07-수직슬라이스-로드맵.md`(M0 행·시퀀스 원칙), `docs/11-구현-배관-보강.md`(§2 GameState/씬 전환).
- Glossary terms: `무녀(Mudang)` 등 — `docs/00-개요-결정-용어.md` §3 용어집. (.forge/CONTEXT.md 없음)
- Related ADRs: none (결정은 `docs/00` 결정 로그 D1·D2·D3·D5·D6-a·D19).
- Definition of Done: Godot 4.3+로 프로젝트를 열어 ① RunScene에서 무녀가 WASD로 이동하고 Camera2D가 추적, ② 스파이크 씬에서 더미 500개가 spatial-hash 직진 이동하며 PC 60fps 유지 — 둘 다 사람이 실행해 확인(헤드리스 UAT 불가).

## Work slices
- [ ] S1. `GameState` autoload(enum S, state·state_changed) 최소 + `Main`(진입점)이 `RunScene`를 로드하는 골격 — `docs/11`§2.1, `docs/06`§3. 완료 기준: Godot 실행 시 RunScene이 에러 없이 뜬다.
- [ ] S2. `InputAdapter`(PC): `move_vector`(Input.get_vector WASD)·`aim_point`+`aim_pressed`(마우스 월드 좌표/클릭)·`rally_pressed` 산출 — `docs/01`§1. 완료 기준: 디버그 라벨에 3종 입력값이 실시간 갱신된다. (depends: S1)
- [ ] S3. `Mudang` 노드(플레이스홀더 Sprite) + WASD 이동(이동속도 220px/s, `docs/09`§0) + `Camera2D` 추적 — `docs/06`§3. 완료 기준(수동): 무녀가 WASD로 움직이고 카메라가 따라온다. (depends: S2)
- [ ] S4. 성능 스파이크(던지는 코드, `tools/bench/` 별도 씬): 더미 500개를 `MultiMeshInstance2D` 1드로우콜로 그리고 균일 격자 spatial hash로 직진 이동, 화면에 FPS 표시 — `docs/06`§1·§2. 완료 기준(수동): PC에서 500개 60fps 유지. 접근법이 안 되면 여기서 드러난다(M-S 진입 전 차단). (depends: S1)

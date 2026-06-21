# 2026-06-21 — M0 프로젝트 골격 + 성능 스파이크 + 무녀 이동

## Plan vs actual
- What went as planned: 4슬라이스 전부 구현(GameState/InputAdapter autoload, Main→RunScene, 무녀 WASD 이동·카메라, 던지는 500더미 MultiMesh 스파이크). 기존 데이터 레이어(`scripts/data`, `data/**`) 무손상. 단일 에이전트로 직접 처리(워크플로우 미사용 — 규모 작음).
- Divergences:
  - UAT 1차 "가운데 네모만, 움직이는지 모르겠다." → **이동 로직은 정상**(헤드리스 `move_check` → `dx=110.00`), 원인은 *카메라가 무녀 자식 + 빈 월드* 라 박스가 화면 중앙 고정처럼 보임(관측 불가). 월드 고정 `BgGrid`(`scripts/bg_grid.gd`) + 디버그 라벨에 무녀 좌표 추가로 해소.
  - 새 `class_name`(BgGrid) 추가 후 헤드리스 부팅이 "Identifier not declared" 파스 에러 → `godot --headless --import` 1회로 전역 클래스 캐시 갱신해야 해소.
  - InputAdapter를 autoload로 확정(계획은 autoload/노드 허용 범위 내).
  - S4 FPS@500은 헤드리스로 측정 불가 → **M-S(스케일업)로 실측 보류**.

## Learnings
- Do differently next time:
  - **플레이어 추적 카메라 탑다운에선 빈 월드라도 월드 고정 시각 기준(그리드/배경/마커)을 처음부터 둔다** — 안 그러면 이동·AI 거동을 눈으로 검증할 수 없다. M1+ 모든 런 씬에 기본 적용.
  - **새 `class_name` 추가 시 헤드리스 검증 전 `godot --headless --import` 선행** — 검증 스크립트에 import 단계를 고정.
  - **GUI 의존 검증(FPS·시각)은 헤드리스로 못 닫는다** — 가능한 로직은 헤드리스 단언으로 증명(`move_check`처럼), 시각·렌더 성능만 사람에게 남긴다. M-S FPS는 반드시 GUI 실측을 게이트로.
  - 던지는 검증 코드(`tools/test/move_check.{gd,tscn}`)는 역할 끝나면 정리(봉인 시 삭제 결정).

## Doc updates
- CONTEXT.md promotion: none (도메인 용어 아님)
- ADR added: none (되돌리기 어려운 결정·트레이드오프 아님)
- 기타: 두 학습 모두 프로세스/구현 학습 → 이 회고 로그가 영구 귀속처(git 추적, 다음 M1 grilling·실행이 읽는 연료). fg-map 생성 문서는 손편집 안 함(자동 재생성).

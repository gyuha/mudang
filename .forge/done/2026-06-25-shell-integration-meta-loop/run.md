<!-- forge-slug: shell-integration-meta-loop -->
# run — 메타 셸 ③: 화면 라우팅 통합 + 메타 루프 흐름 테스트 (C3 종결)
fg-loop 드라이브 task 23 (마지막). eco on. 워크플로우 없이 직접 실행.

## 계획대로
- S1 main.gd 라우팅: BOOT→곧장 RUN 제거 → `GameState.state_changed` 구독 + `set_state(DASHBOARD)` 진입. `_on_state_changed`가 상태별 화면 노드(_screen) 교체 — DASHBOARD→Dashboard, LOADOUT→Loadout, RUN→RunScene, RESULT→Result. BOOT/BRIEFING/LEVELUP_PAUSE는 교체 안 함(레벨업은 RunScene 위 오버레이, get_tree().paused로 처리).
- S2 meta_loop_check.gd+.tscn: Main 인스턴스→DASHBOARD→스테이지1 선택(LOADOUT)→편성 1명 확정(RUN)→런 강제 승리(stage1 duration 축소+수동 1틱)→RESULT(last_result=win)→세이브 확인(stage_hwalinseo cleared+unlocked)→대시보드 복귀. 각 단계 AND.
- S3 전체 회귀 25체크 green + main 부팅(→DASHBOARD) 에러 0 (C1·C2 동시 충족).

## 분기(divergence)
1. **승리 강제는 수동 _physics_process 구동**: `await get_tree().physics_frame`로는 헤드리스에서 RunScene가 결정적으로 구동되지 않아 _run_time이 안 올랐다. stage456_check 검증 패턴(`set_physics_process(false)` 후 `rs._physics_process(0.1)` 직접 호출)으로 교체 → 결정적 승리 트리거. 승패 조건 자체는 stage*_check가 검증하므로 여기선 라우팅만 본다(stage1 duration 축소는 흐름 트리거 수단).
2. **메타 저장은 RunScene가 수행, Result는 표시·복귀만**: set_state(RESULT)가 _physics_process 안에서 동기 발화 → Main이 즉시 Result로 교체(rs queue_free는 프레임 끝까지 지연되어 직후 메타 저장 블록 정상 실행). 중복 저장 없음(_meta_saved 가드).

## 검증
- meta_loop_check VERDICT => PASS: boot→dashboard · select→loadout · confirm→run · run→result(win) · meta saved(cleared+unlocked) · result→dashboard 전부 true.
- 전체 회귀 25체크 FAIL 0 · SCRIPT_ERR 0.
- main.tscn 부팅(→DASHBOARD, 5프레임) not found/SCRIPT/Parse 에러 0.

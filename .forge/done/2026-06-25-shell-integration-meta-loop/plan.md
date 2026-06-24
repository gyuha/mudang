<!-- forge-slug: shell-integration-meta-loop -->
<!-- task: 23 -->
<!-- tdd: off -->
<!-- priority: low -->
<!-- generated-by: fg-loop -->
# 메타 셸 ③ — 화면 라우팅 통합 + 메타 루프 흐름 테스트 (C3 종결)

## Goal / Non-goals
- Goal: `main.gd`를 BOOT→곧장 RUN이 아니라 BOOT→DASHBOARD로 진입시키고, `GameState.state_changed`에 따라 현재 화면 노드를 교체(대시보드/편성/런/결과)하도록 배선한다. 그리고 메타 루프 전체를 검증하는 `meta_loop_check.tscn`을 작성해 C3를 종결한다.
- Non-goals: 신규 화면 추가(BRIEFING은 예약), 셸 시각 폴리시, 트랜지션 애니.

## Source of truth
- Glossary terms: 화면 전이, Main, GameState in .forge/CONTEXT.md
- Related ADRs: docs/11 §2.1(Main이 state에 따라 화면 노드 교체), docs/10(메타 루프)
- Definition of Done: `main.tscn` 부팅 시 대시보드가 뜨고(headless 인스턴스 OK), `meta_loop_check.tscn`이 `VERDICT => PASS`. (depends: shell-dashboard-stage-select, shell-loadout-result)

## 설계 메모
- `main.gd`: `GameState.state_changed`를 구독해 상태별 화면 노드를 add/remove. DASHBOARD→dashboard.tscn, LOADOUT→loadout.tscn, RUN→RunScene, RESULT→result.tscn. LEVELUP_PAUSE는 RUN 위 오버레이(기존 처리 유지).
- 시작 상태를 BOOT→DASHBOARD로(기존 BOOT→RUN 제거). RunScene는 RUN 진입 시 `selected_stage_path`/`selected_companions`를 읽어 그대로 동작(이미 read).
- `meta_loop_check.gd`: 대시보드 인스턴스 → 해금 스테이지 선택(selected_stage_path 설정 + LOADOUT) → 편성 확정(RUN) → RunScene 강제 승리(보스 처치 또는 duration; stage3+는 kill_boss) → RESULT 전이 확인 → MetaProgress 해금 저장 확인(stage_records/unlocked_stages 갱신) → "대시보드로"(DASHBOARD) → 처음 화면 복귀. 각 단계 bool AND → `VERDICT => PASS`.

## Work slices
- [ ] S1. `main.gd` 라우팅 — 완료 기준: BOOT→DASHBOARD 진입, `state_changed`로 DASHBOARD/LOADOUT/RUN/RESULT 화면 노드 교체. `main.tscn` headless 부팅 시 대시보드 노드 존재, ERROR 0.
- [ ] S2. `tools/test/meta_loop_check.gd`+`.tscn` — 완료 기준: 위 흐름(선택→런→승리→해금 저장→대시보드 복귀)을 headless로 구동해 각 단계 통과 시 `VERDICT => PASS`. (depends: S1)
- [ ] S3. 전체 회귀 green — 완료 기준: `tools/test/*_check.tscn` 전부 PASS, `main.tscn` 부팅 파스/리소스 에러 0(C1·C2 동시 충족). (depends: S1, S2)

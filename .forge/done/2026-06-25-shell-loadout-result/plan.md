<!-- forge-slug: shell-loadout-result -->
<!-- task: 22 -->
<!-- tdd: off -->
<!-- priority: medium -->
<!-- generated-by: fg-loop -->
# 메타 셸 ② — 편성(로드아웃) + 결과 화면

## Goal / Non-goals
- Goal: `GameState.S.LOADOUT`와 `S.RESULT` 두 화면을 구현한다. LOADOUT: 해금 동료 풀(3종)에서 `MetaProgress.loadout_slots`(2)만큼 선택 → RUN 전이. RESULT: 런 결과(win/lose) 표시, 승리 시 `MetaProgress.record_clear` + 해금 저장, "대시보드로" → DASHBOARD 전이.
- Non-goals: 대시보드/스테이지 선택(task 21), main.gd 라우팅·흐름 테스트(task 23), 동료 능력 미리보기·상세, 메타 화폐 정산 UI.

## Source of truth
- Glossary terms: 편성/로드아웃, loadout_slots, 결과 화면, record_clear in .forge/CONTEXT.md
- Related ADRs: docs/10(편성·결과), docs/11 §2.1(GameState 전이), docs/03 §5(메타 해금/저장), docs/12(동료 로스터)
- Definition of Done: `Loadout` 씬이 3 동료 노출·슬롯 2 선택 후 선택된 편성을 RunScene가 읽을 수 있는 곳(GameState 또는 전달 경로)에 기록하고 RUN 전이. `Result` 씬이 win/lose를 받아 표시하고, win이면 해금 저장 1회, "대시보드로"가 DASHBOARD 전이를 일으킨다.

## 설계 메모
- 신규 `scripts/ui/loadout.gd`+`scenes/loadout.tscn`, `scripts/ui/result.gd`+`scenes/result.tscn`. 기존 `scripts/ui/*` 관습 준수.
- 동료 풀: data/companions/hwarang(탱)·hwaljabi(딜)·gyeonseup(힐). 선택 결과를 RunScene가 소비할 통로 필요 — 기존에 없으면 `GameState.selected_companions: Array[String]`(경로 배열) 추가가 가장 단순(eco). RunScene가 이를 읽어 동료 스폰(현재 하드코딩이면 그 자리 교체).
- RESULT: RunScene가 승패 결정 시 GameState를 RESULT로 전이(이미 run_scene.gd가 함). Result 화면은 `GameState`/RunScene의 결과값을 읽어 표시. 승리 해금 저장은 이미 run_scene M7 정산이 1회 수행 — Result는 표시 + 대시보드 복귀 책임만(중복 저장 금지).

## Work slices
- [ ] S1. `loadout.gd`+`.tscn` — 완료 기준: headless 인스턴스 시 해금 동료 3종 노출, 슬롯 2 선택 가능, "출전" 확정 시 선택 편성이 `GameState.selected_companions`(또는 합의된 통로)에 기록되고 `set_state(RUN)`.
- [ ] S2. RunScene가 편성 통로를 소비 — 완료 기준: `GameState.selected_companions`가 설정돼 있으면 RunScene가 그 동료들을 스폰(비었으면 기존 기본 편성 폴백). 기존 회귀 green 유지.
- [ ] S3. `result.gd`+`.tscn` — 완료 기준: win/lose를 받아 표시, 승리 시 정산이 이미 됐음을 전제로 중복 저장 없이 결과만 표시, "대시보드로" 버튼/호출이 `set_state(DASHBOARD)`.

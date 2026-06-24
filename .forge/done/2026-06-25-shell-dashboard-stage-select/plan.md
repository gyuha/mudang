<!-- forge-slug: shell-dashboard-stage-select -->
<!-- task: 21 -->
<!-- tdd: off -->
<!-- priority: medium -->
<!-- generated-by: fg-loop -->
# 메타 셸 ① — 대시보드 + 스테이지 선택 화면

## Goal / Non-goals
- Goal: `GameState.S.DASHBOARD` 화면을 구현한다. MetaProgress(`user://save.json`)를 읽어 6스테이지를 목록으로 보여주고, `unlocked_stages` 해금 게이트를 적용하며, 스테이지 선택 시 `GameState.selected_stage_path`를 설정하고 다음 상태(LOADOUT)로 전이한다.
- Non-goals: 편성/결과 화면(task 22), main.gd 라우팅·흐름 테스트(task 23), 브리핑(BRIEFING 예약), 메타 화폐 상점.

## Source of truth
- Glossary terms: 대시보드, 스테이지 선택, MetaProgress.unlocked_stages in .forge/CONTEXT.md
- Related ADRs: docs/10(대시보드·스테이지 선택·6스테이지), docs/11 §2.1(화면 전이=GameState), docs/03 §5(메타)
- Definition of Done: `Dashboard` 씬이 headless 인스턴스 가능, 6 StageDef를 노출, 잠긴 스테이지는 선택 불가, 해금 스테이지 선택 시 `GameState.selected_stage_path`가 해당 .tres로 설정되고 `GameState.set_state(LOADOUT)` 호출. (흐름 전체 검증은 task 23의 meta_loop_check)

## 설계 메모
- 신규 `scripts/ui/dashboard.gd` + `scenes/dashboard.tscn`. 기존 UI(`scripts/ui/*.gd`)의 코드 스타일·노드 구성 관습을 따른다.
- 6 StageDef: stage_hwalinseo / stage_musnyeo_village / stage_mountain_pass / stage_yangban_gut / stage_seonsucheong / stage_palace_wraith. 기본 해금 = 1장(또는 MetaProgress.unlocked_stages 비었을 때 1장만).
- MetaProgress는 autoload 아님 — 대시보드가 `MetaProgress.load()`(있으면) 또는 신규 인스턴스로 로드. 저장 파일 없으면 1장만 해금된 신규 상태.
- 배경은 task 19의 `assets/bg/title_bg.png` 사용(없으면 폴백).

## Work slices
- [ ] S1. `MetaProgress` 로드 진입점 확인/보강 — 완료 기준: 저장 파일이 없을 때 1장만 해금된 기본 MetaProgress를 얻는 경로가 존재(없으면 추가). 정적 `load()`/`get_or_create` 형태.
- [ ] S2. `dashboard.gd` + `dashboard.tscn` 구현 — 완료 기준: headless 인스턴스 시 6 스테이지 항목 생성, 각 항목에 잠금/해금 상태 반영(잠긴 항목은 disabled/비선택).
- [ ] S3. 선택 → 전이 배선 — 완료 기준: 해금 스테이지 항목 활성화(예: `select_stage(path)` 호출) 시 `GameState.selected_stage_path == path` 이고 `GameState.state == DASHBOARD→LOADOUT` 전이. 잠긴 항목 선택은 무시(전이 없음).

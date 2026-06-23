<!-- forge-slug: m7-meta-progress -->
<!-- task: 8 -->
<!-- priority: high -->
<!-- tdd: off -->
# M7 영구메타 — MetaProgress 저장/로드 · 클리어 해금·정산 (편성 UI 제외)

## Goal / Non-goals
- Goal: 런을 넘어 저장되는 **MetaProgress**(해금 스테이지/동료, 메타 재화, 스테이지 기록)를 `user://save.json`(version+migration)으로 영속하고, **스테이지 클리어 시 보상 정산 + 해금**을 기록한다. M6 승리 → 메타 저장 사이클의 backend. (docs/03 §4·§5, docs/11 §3, D15·D16)
- Non-goals (**human/GUI wall — 별도**):
  - 편성 화면(loadout) UI·대시보드·결과 화면 — M7-UI/M8 (헤드리스는 저장/해금 데이터만)
  - 메타 업그레이드 **효과 적용**(무녀/동료 시작 스탯 주입) — 구조만 영속, 적용은 후속(런 주입 배선)
  - M-S 렌더/FPS, M8 폴리시/밸런스, ★재미검증★

## Source of truth
- Glossary terms: 영구메타=MetaProgress, 출전 편성=Loadout (docs/00 §3). `.forge/CONTEXT.md` 미생성.
- Related ADRs: docs/00 §2 — **D15**(가벼운 영구메타), **D16**(편성/슬롯 2→4). 스키마: docs/11 §3.1(version/unlocked_stages/unlocked_companions/loadout_slots/meta_currency/meta_upgrades/stage_records/tutorial_done), docs/03 §5. StageReward(meta_currency/first_clear_bonus) 기존.
- Definition of Done: `tools/test/meta_check` 헤드리스 PASS — (1) 신규 MetaProgress 기본값, (2) record_clear 시 cleared/best_time/재화 정산(첫 클리어 보너스 1회만)/동료·스테이지 해금, (3) save→load 영속, (4) 구버전/누락 파일 load 시 migration 안전. M1~M6 회귀 정상.

## Work slices
- [ ] S1. `MetaProgress`(`scripts/systems/meta_progress.gd`): 필드(version/unlocked_stages/unlocked_companions/loadout_slots=2/meta_currency/meta_upgrades/stage_records/tutorial_done) + `save()`(user://save.json) + static `load_or_new()`(없으면 기본값, version<CURRENT면 `_migrate`) — completion criterion: 기본값 생성·save·load 왕복이 동일 상태 복원(헤드리스 PASS)
- [ ] S2. 클리어 정산·해금: `record_clear(stage: StageDef, clear_time: float)` — stage_records[id]={cleared:true, best_time} 갱신, 첫 클리어면 reward.first_clear_bonus 1회 + 매 클리어 reward.meta_currency 적립, stage.unlock_companion 해금, stage.id를 unlocked_stages에 추가 — completion criterion: 첫/재클리어 정산이 정확(보너스 1회), 해금 집합 갱신(헤드리스 PASS) (depends: S1)
- [ ] S3. RunScene 연결: M6 승리(_result==win) 시 MetaProgress.load_or_new→record_clear(_stage, _run_time)→save 1회(중복 방지 가드). 디버그 라벨에 해금/재화 표시 — completion criterion: 승리 런 후 save.json에 cleared/재화 기록(통합/헤드리스) (depends: S2)
- [ ] S4. 헤드리스 체크 `tools/test/meta_check.*`(기본값/정산/영속/migration) + import 선행 + M1~M6 회귀 — completion criterion: `godot --headless` 전 체크 PASS, 회귀 정상 (depends: S2)

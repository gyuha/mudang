<!-- forge-slug: m5-growth-logic -->
<!-- task: 6 -->
<!-- priority: high -->
<!-- tdd: off -->
# M5 성장 로직 — EXP 곡선 · 레벨업 · 무녀 업그레이드 적용 (UI 제외)

## Goal / Non-goals
- Goal: 혼불로 적립되는 EXP가 **레벨업**을 일으키고, 무녀 업그레이드가 **데이터 주도로 레버 파라미터를 강화**하는 backbone을 구현. 동료 EXP→레벨업은 **pending 적립 + 아이콘 플래그**까지(적용/선택 UI는 분리). (docs/03 §2·§3, docs/01 §6, docs/09 §4, D11)
- Non-goals (**human wall — 의도적 분리, 별도 M5-UI 작업**):
  - **일시정지 3택 UI·카드 렌더·클릭 선택·비정지 동료 보류카드 UX·"흐름 안 끊김" 체감** — GUI/feel, 사람 필요 (헤드리스는 곡선/적립/적용 로직만; 선택은 auto-pick 플레이스홀더)
  - **동료 업그레이드 적용**(역할별 효과 + 공유 CompanionDef 변이 회피 위해 인스턴스 오버라이드 설계 필요) — M5-UI/후속
  - 무녀 생존 카드(max_hp는 현재 const) — HP를 var로 바꾸는 별도 작업
  - 리롤, 전체 19카드 — 데이터 추가(D4), 대표 4카드로 framework 증명

## Source of truth
- Glossary terms: none. `.forge/CONTEXT.md` 미생성.
- Related ADRs: docs/00 §2 — **D11**(무녀·동료 3택), **D7**(서포터 강화만). 수치 docs/01 §6(`exp_to_next(n)=floor(8*1.15^(n-1))`), docs/03 §3(동료 `floor(6*1.18^(n-1))`, pending 상한 3), docs/09 §4(카드 풀).
- Definition of Done: `tools/test/growth_check` 헤드리스 PASS — (1) 무녀 EXP 곡선이 공식과 일치, (2) EXP 누적→레벨업→pending++, (3) 무녀 업그레이드 적용 시 레버 파라미터가 델타만큼 증가(데이터 주도), (4) 동료 EXP→레벨업→pending_upgrades++(상한 3). M1~M4 회귀 정상.

## Work slices
- [ ] S1. `MudangUpgrade` 리소스(`scripts/data/mudang_upgrade.gd`: id/display_name/category/max_level/`targets: Array[StringName]`/`deltas: Array[float]`) + 대표 4 .tres(오라확장 aura_radius+20 / 오라심화 slow_multiplier-0.05 / 넉백강화 knockback_force+60·knockback_radius+12 / 전달가속 transfer_rate_max+3). 전부 Mudang @export 레버 파라미터 타겟 — completion criterion: 4 .tres 로드 무오류, targets가 Mudang 실제 속성명과 일치
- [ ] S2. 무녀 레벨업: Mudang에 `mudang_level`/`_pending_picks` + `func exp_to_next(n)`(docs 공식) + `func add_exp(v)`(누적, 임계 도달 시 level++/pending++/초과분 이월) + `func apply_upgrade(up)`(targets/deltas로 `set(param, get(param)+delta)`). SoulfireSystem 흡수가 `add_exp` 호출하도록 변경 — completion criterion: exp_to_next 값이 공식과 일치, 충분 EXP 시 레벨업+pending, apply_upgrade 후 해당 파라미터 증가(헤드리스 PASS) (depends: S1)
- [ ] S2b. 동료 레벨업 감지: Companion에 `companion_level`/`pending_upgrades` + `func add_companion_exp(v)`(docs 동료 곡선, 레벨업 시 pending_upgrades++ 상한 3) + `has_pending()` 플래그(머리 위 아이콘=M5-UI). SoulfireSystem 전달이 `add_companion_exp` 호출하도록 변경 — completion criterion: 동료 EXP 누적→레벨업→pending_upgrades++, 상한 3 클램프(헤드리스 PASS) (depends: S1)
- [ ] S3. RunScene auto-pick 플레이스홀더: 매 프레임 무녀 _pending_picks>0이면 풀에서 미만렙 카드 1개 auto-pick→apply_upgrade→pending-- (3택 UI/일시정지는 M5-UI Non-goal, 여기선 흐름 검증용 자동선택). 디버그 라벨에 무녀 레벨/EXP·동료 레벨/pending 표시 — completion criterion: 런에서 무녀 레벨업 시 레버가 자동 강화됨(통합 체크) (depends: S2)
- [ ] S4. 헤드리스 체크 `tools/test/growth_check.*`(곡선/무녀레벨업+적용/동료레벨업+pending상한) + import 선행 + M1~M4 회귀 — completion criterion: `godot --headless` 전 체크 PASS, 회귀 정상 (depends: S2, S2b, S3)

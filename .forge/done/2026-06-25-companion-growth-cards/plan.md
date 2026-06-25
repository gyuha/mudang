<!-- forge-slug: companion-growth-cards -->
<!-- task: 27 -->
<!-- tdd: off -->
<!-- priority: medium -->
<!-- generated-by: fg-loop -->
# 동료 성장 카드 — CompanionUpgrade 데이터 + 적용 (레벨업이 실제 강화로)

## Goal / Non-goals
- Goal: 동료 레벨업이 실제 강화로 이어지게 한다. CompanionUpgrade 리소스(역할/공통 카드) + 적용 로직 구현 — 동료가 레벨업해 쌓인 pending을 카드로 소비하면 인스턴스 스탯(공격력/HP/힐 등)이 상승한다. **공유 CompanionDef 리소스는 변형하지 않고 인스턴스 레벨 보너스**로 적용(무녀의 mudang_upgrade 패턴 대응).
- Non-goals: 비정지 3택 슬로모/렌더/클릭 UI(M5-UI GUI — 자동 최선픽으로 적용), 가중 추첨(앞에서부터 순차), 동료별 고유 능동 기믹(docs/12 후속).

## Source of truth
- Glossary terms: 동료 성장, CompanionUpgrade, pending_upgrades in .forge/CONTEXT.md
- Related ADRs: docs/03 §3(동료 성장 비정지 3택), docs/09 §4
- Definition of Done: companion_growth_card_check가 `VERDICT => PASS` — 동료 EXP로 레벨업→pending→카드 적용→인스턴스 스탯 상승 확인, 공유 def 비변형(다른 인스턴스/리로드에 누수 없음).

## 설계 메모
- `scripts/data/companion_upgrade.gd`(class_name CompanionUpgrade): id, display_name, role_filter(공통/tank/ranged/healer), targets(스탯명 배열), deltas(가산값), max_level — mudang_upgrade.gd 구조 차용.
- Companion 인스턴스: 스탯을 def에서 직접 읽는 부분을 "기본(def) + 누적 보너스" 합으로 바꿈(인스턴스 필드 `_atk_bonus`/`_hp_bonus` 등 또는 보너스 Dictionary). def는 읽기 전용.
- 적용 진입점: 동료 pending 소비 시 적용 가능(미만렙) 카드 중 자동 최선픽(앞에서부터) — UI 없이 비정지 자동 적용(M5-UI Non-goal대로). `apply_companion_upgrade(up)` 메서드.
- data/upgrades/ 아래 카드 .tres 몇 종(공통: 체력강화/공격강화, 역할별 1~2종) 작성.

## Work slices
- [ ] S1. tools/test/companion_growth_card_check.gd+.tscn(먼저) — 완료 기준: 동료 1인 로드 → add_companion_exp로 레벨업(pending 발생) → 카드 적용 → 인스턴스 공격력(또는 max_hp) 증가 확인 AND 동일 def로 만든 새 인스턴스는 보너스 없음(공유 비변형). 현재(미구현)엔 FAIL.
- [ ] S2. CompanionUpgrade 리소스 + 카드 데이터 — 완료 기준: companion_upgrade.gd 클래스 + data/upgrades/comp_*.tres 몇 종, validate/로드 OK.
- [ ] S3. Companion 인스턴스 보너스 적용 + pending 소비 — 완료 기준: 스탯 = def 기본 + 누적 보너스, apply_companion_upgrade가 pending 감소+보너스 가산. RunScene가 동료 pending을 자동 최선픽으로 소비(비정지). companion_growth_card_check PASS.
- [ ] S4. 회귀 무파손 — 완료 기준: growth_check/companion_ai_check 등 기존 체크 green, main 부팅 에러 0.

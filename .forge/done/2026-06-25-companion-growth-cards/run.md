<!-- forge-slug: companion-growth-cards -->
# run — 동료 성장 카드: CompanionUpgrade 데이터 + 적용 (레벨업이 실제 강화로)
fg-loop 드라이브 task 27. eco on. 워크플로우 없이 직접 실행.

## 계획대로
- S1 companion_growth_card_check.gd+.tscn(먼저): 동료 레벨업 pending→카드 적용→인스턴스 스탯 상승 + 공유 def 비변형 + 역할 필터 검증.
- S2 `scripts/data/companion_upgrade.gd`(class_name CompanionUpgrade): id/display_name/role_filter/max_level/targets/deltas, applies_to(role), apply_to(c)=c.def 속성에 델타 가산. data/upgrades/companion/ comp_vitality(any·max_hp+20)·comp_power(any·attack_damage+3)·comp_mending(healer·heal_per_sec+2).
- S3 Companion 인스턴스 보너스 + pending 소비: `_ready`에서 `def = def.duplicate()`(인스턴스 전용 복사본 → 카드가 공유 리소스 비변형). `_upgrade_levels`(카드별 레벨), `can_take_upgrade`(역할+미만렙), `apply_companion_upgrade`(적용+레벨기록+pending-1). RunScene `_auto_pick_companion_upgrade`로 비정지 자동 최선픽 소비(매 step).
- S4 회귀: 전체 28체크 green, main 부팅 에러 0.

## 분기(divergence)
1. **인스턴스 분리 = def.duplicate()(읽기사이트 무변경)**: 동료가 스탯을 `def.X`로 직접 읽으므로, _ready에서 def를 복제해 인스턴스 전용으로 만들면 기존 모든 `def.X` 읽기가 자동으로 보너스를 반영하고 공유 캐시 리소스는 안 건드린다. mudang_upgrade의 set/get 패턴을 복제본에 적용 — 읽기 사이트 일괄 수정보다 훨씬 surgical. 검증: 새로 load한 def는 원본값 유지(8.0).
2. **비정지 자동 최선픽(UI 없음)**: M5-UI(슬로모/3택 클릭)는 Non-goal대로 미구현. RunScene가 매 step 동료 pending을 역할일치+미만렙 카드 중 앞에서부터 자동 적용(만렙뿐이면 중단 — 무한 방지).
3. **카드 3종(슬라이스)**: 공통 2(기력단련/무예연마) + 힐러 전용 1(치유강화). 추가 역할별 카드는 후속.

## 검증
- companion_growth_card_check VERDICT => PASS: pending 3→2(소비) · attack_damage 8→11(카드) · 공유 def 비변형(fresh load 8.0) · 역할필터(healer 카드 tank 적용불가).
- 전체 회귀 28체크 FAIL 0 · SCRIPT_ERR 0 · main 부팅 0.

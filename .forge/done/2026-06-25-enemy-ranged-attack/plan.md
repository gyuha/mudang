<!-- forge-slug: enemy-ranged-attack -->
<!-- task: 25 -->
<!-- tdd: off -->
<!-- priority: high -->
<!-- generated-by: fg-loop -->
# 적 원거리 공격 — ranged ai_kind (사거리 정지 + 주기적 원거리 피해)

## Goal / Non-goals
- Goal: `ai_kind == "ranged"`(mask_spirit) 적이 타겟에 무한 접근하지 않고 사거리에서 멈춰 거리를 유지하며, 접촉 없이 주기적으로 타겟 동료에게 원거리 피해를 준다. 직진(접촉) 적과 명확히 구분되는 거동.
- Non-goals: 투사체 노드/궤적 비주얼(직접 피해로 처리), 탄막/유도, plague의 독장판(별도 해저드 — 미포함), 원거리 적의 카이팅 후퇴(정지 유지로 충분).

## Source of truth
- Glossary terms: ranged(ai_kind) in .forge/CONTEXT.md
- Related ADRs: docs/04 §1(ranged 거동), docs/09 §2(적 수치)
- Definition of Done: enemy_ranged_check가 `VERDICT => PASS` — ranged 적이 사거리 근방에서 거리 유지(접근 정지) + 접촉 거리 밖에서 타겟 HP가 주기적으로 감소.

## 설계 메모
- EnemyDef에 원거리 필드 추가(최소): `attack_range: float`(예 220), `attack_period: float`(예 1.2), 피해는 기존 `contact_damage` 재사용 또는 `ranged_damage`. mask_spirit.tres에 값 설정.
- enemy_system tick: ranged 적은 `to.length() > attack_range`면 접근, 이하이면 정지(이동 0) + 내부 쿨다운 타이머로 attack_period마다 타겟 동료에 피해. 타겟은 task 24의 타겟 선택 결과(ranged는 동료 우선이 자연스러움 — target_companion류).
- 쿨다운은 슬롯별 배열(`_atk_cd: PackedFloat32Array`) 추가, kill swap-remove 시 함께 스왑.
- 피해 적용은 타겟 Companion.take_contact_damage(혹은 동등 메서드) 재사용.

## Work slices
- [ ] S1. tools/test/enemy_ranged_check.gd+.tscn(먼저) — 완료 기준: ranged 적 1 + 동료 1(접촉 사거리 밖 위치)을 두고 다수 tick → 적이 attack_range 근방에서 거리 유지(동료에 접촉 안 함) + 동료 HP가 시간에 따라 감소. 현재(원거리 없음)엔 FAIL.
- [ ] S2. EnemyDef 원거리 필드 + mask_spirit 데이터 — 완료 기준: attack_range/attack_period(+피해) 필드 추가, mask_spirit.tres 값 설정, validate 통과.
- [ ] S3. enemy_system ranged 거동 구현 — 완료 기준: ranged 적 정지+주기 피해, 슬롯 쿨다운 배열 swap-remove 정합. enemy_ranged_check PASS.
- [ ] S4. 회귀 무파손 — 완료 기준: 기존 체크 전부 green(특히 contact_damage/perf500/stage*), main 부팅 에러 0.

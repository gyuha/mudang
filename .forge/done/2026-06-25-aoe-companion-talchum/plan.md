<!-- forge-slug: aoe-companion-talchum -->
<!-- task: 28 -->
<!-- tdd: off -->
<!-- priority: high -->
<!-- generated-by: fg-loop -->
# 광역 동료 탈쓴퇴마사 — aoe role (광역 베기 다중 피해)

## Goal / Non-goals
- Goal: `role_id=aoe` 동료 거동을 구현하고 탈쓴퇴마사 직업을 추가한다. 광역 베기 = 타겟 주변 반경 내 적 다수를 동시에 피해(단일타겟 대비). 도발+받피(화랑보다 공격적, docs/12 §3.1). 탈쓴퇴마사 CompanionDef .tres + 스프라이트(codex-image).
- Non-goals: 쇠사슬 견인(역넉백 — docs/12 §4 예약, 신규 엔티티 필요), 부채꼴 각도 판정(반경 원으로 근사), 편성 화면 노출(별도 — 풀 추가만), 고유 연출/파티클.

## Source of truth
- Glossary terms: aoe(role_id), 광역 베기, 탈쓴퇴마사 in .forge/CONTEXT.md
- Related ADRs: docs/12 §3.1(탈쓴퇴마사·aoe), docs/02 §2(동료 거동), docs/09(수치)
- Definition of Done: aoe_companion_check가 `VERDICT => PASS` — aoe 동료의 1회 공격이 반경 내 적 ≥2를 피해, role_id=aoe, 탈쓴퇴마사 .tres + 스프라이트 존재. 회귀 무파손.

## 설계 메모
- CompanionDef에 `aoe_radius: float = 0.0`(>0이면 광역) 추가. 탈쓴퇴마사: role_id=aoe, taunt_radius>화랑, damage_reduction>화랑, attack_damage 중간, aoe_radius 예 90.
- companion.gd 공격부: 현재 `enemies.apply_damage(_target_idx, attack_damage)`(단일). aoe role이면 타겟 위치 기준 `enemies.query_circle(target_pos, aoe_radius)`로 인덱스들 받아 각각 apply_damage. 타게팅/이동은 tank 유사(전열). _eff 스탯(task 27 성장)과 호환.
- 데이터: data/companions/talchum.tres(id=talchum, display_name="탈 쓴 퇴마사"). 스프라이트 assets/sprites/talchum.png codex-image(투명 PNG, 무녀/동료 톤). 룸 추가: RunScene 기본 풀이나 Loadout BASE_COMPANIONS는 건드리지 않음(풀 확장은 Non-goal — 데이터만).

## Work slices
- [ ] S1. tools/test/aoe_companion_check.gd+.tscn(먼저): 탈쓴퇴마사 인스턴스 + 적 다수(반경 내 3마리) 배치 → 1회 공격 → ≥2마리 피해(또는 처치) 확인 + role_id=aoe + 스프라이트 존재. 미구현 시 FAIL.
- [ ] S2. CompanionDef aoe_radius 필드 + talchum.tres(스탯) 작성.
- [ ] S3. 탈쓴퇴마사 스프라이트 codex-image 생성(assets/sprites/talchum.png, 포그라운드 단일 호출, 투명) + 임포트.
- [ ] S4. companion.gd aoe 공격 분기(query_circle 다중 apply_damage). aoe_companion_check PASS.
- [ ] S5. 회귀 무파손: 기존 체크 green, main 부팅 0.

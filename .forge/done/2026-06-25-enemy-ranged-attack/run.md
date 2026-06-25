<!-- forge-slug: enemy-ranged-attack -->
# run — 적 원거리 공격: ranged ai_kind (사거리 정지 + 주기 원거리 피해)
fg-loop 드라이브 task 25. eco on. 워크플로우 없이 직접 실행.

## 계획대로
- S1 enemy_ranged_check.gd+.tscn(먼저): 동료1(원점)+ranged 적(400)을 두고 80틱 → 적이 사거리 근방에서 정지(접촉 거리 밖) + 동료 HP 감소 검증.
- S2 EnemyDef 원거리 필드 추가: `attack_range`(기본0=근접), `attack_period`. mask_spirit.tres에 attack_range=220, attack_period=1.2.
- S3 enemy_system ranged 거동: SoA에 `_atk_cd`(슬롯 쿨다운, spawn/kill swap 정합) 추가. tick에서 `ai_kind==ranged && attack_range>0`이면 `_tick_ranged`로 분기 — 최근접 동료까지 접근 후 attack_range에서 정지, _atk_cd 0 도달 시 동료 take_contact_damage(contact_damage) 발사 후 attack_period 리셋. 동료 없으면 최근접 아군 접근 폴백.
- S4 회귀: 전체 27체크 green, main 부팅 에러 0, perf500 PASS(0.546ms).

## 분기(divergence)
1. **원거리 피해는 투사체 없이 직접 적용**: 노드/궤적 비주얼 없이 사거리 내에서 take_contact_damage 직접 호출(접촉 시스템 재사용). 비주얼/탄막은 폴리시 후속(스코프 명시).
2. **피해값은 contact_damage 재사용**: 별도 ranged_damage 필드 없이 mask_spirit의 contact_damage(4)를 원거리 피해로 사용 — 적이 사거리 유지로 접촉이 안 일어나므로 충돌 없음.
3. **plague는 그대로 rush_companion**: plague(독장판)는 ranged 아님 — 독장판은 해저드 영역 후속, 이번 스코프 제외.

## 검증
- enemy_ranged_check VERDICT => PASS: 적 최종거리 218.5(사거리 220, 접촉 18 — 정지 유지) · 동료 HP 200→184(접촉 없이 원거리 피해).
- 전체 회귀 27체크 FAIL 0 · SCRIPT_ERR 0 · main 부팅 0 · perf500 PASS(tick 0.546ms<16.6).

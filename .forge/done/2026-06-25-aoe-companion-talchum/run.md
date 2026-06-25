<!-- forge-slug: aoe-companion-talchum -->
# run — 광역 동료 탈쓴퇴마사: aoe role (광역 베기 다중 피해)
fg-loop 드라이브 task 28. eco on. 워크플로우 없이 직접 실행.

## 계획대로
- S1 aoe_companion_check.gd+.tscn(먼저): 군집 적 3 + 탈쓴퇴마사 1회 광역 공격 → ≥2 처치 + role_id=aoe + 스프라이트 존재.
- S2 CompanionDef `aoe_radius` 필드 + data/companions/talchum.tres(role_id=aoe, max_hp150, taunt 150>화랑, dr 0.25>화랑, attack 6/0.7s, attack_range 55, aoe_radius 90).
- S3 talchum 스프라이트 codex-image(투명 1024 RGBA, 탈/붉은부적/곡도, 기존 동료 톤) → assets/sprites/talchum.png + 임포트.
- S4 enemy_system `apply_damage_circle(center,r,amount)`(내림차순 안전 — 처치 swap-remove가 낮은 대상 슬롯 비파괴) + companion `_try_attack` aoe 분기(aoe_radius>0이면 query_circle 다중 apply_damage).
- S5 회귀 30체크 green, main 부팅 0.

## 분기(divergence)
1. **광역 처치 swap-remove 안전**: apply_damage_circle가 query_circle 스냅샷을 내림차순 처리 — 처치 시 꼬리 스왑이 더 낮은 인덱스(아직 처리할 대상)를 덮지 않음. 군집 3마리 동시 처치 검증(double-hit/누락 없음).
2. **풀 추가는 데이터만**: 탈쓴퇴마사를 기본 출전 풀/Loadout BASE에 넣지 않음(스코프 — 풀 확장 Non-goal). .tres+스프라이트만 추가, 광역 거동 검증.
3. **쇠사슬 견인(역넉백) 미구현**: docs/12 §4 예약(신규 엔티티). 광역 베기(반경 다중 피해)만 구현, 부채꼴 각도는 원으로 근사.
4. **codex 중간물 tmp/**: talchum_chromakey.png는 tmp/imagegen/(gitignore)에 생성된 codex 중간 산출물 — 정식 에셋 아님.

## 검증
- aoe_companion_check VERDICT => PASS: role=aoe · aoe_radius=90 · 스프라이트 존재 · 군집 3마리 광역 동시 처치(active 3→0, ≥2).
- 전체 회귀 30체크 FAIL 0 · SCRIPT_ERR 0 · main 부팅 0.

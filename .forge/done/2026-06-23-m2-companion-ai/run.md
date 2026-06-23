<!-- forge-slug: m2-companion-ai -->
# run — M2 동료 AI (계획 대비 실제)

실행: 단일 에이전트 직접 구현(Dynamic Workflow 미사용 — 슬라이스가 소수 파일을 순차·결합 수정해 병렬 fan-out 이득 없음, fg-run "small scale → 직접" 지침). 검증: 헤드리스 `godot --headless --path . tools/test/*.tscn`.

## 계획대로 된 것
- S1 `CompanionDef`(단일, role_id 분기, D25) + 3 .tres(hwarang/hwaljabi/gyeonseup). 수치 docs/09 §1 일치(견습무당 attack_damage=0 지원 전용). EnemyDef 컨벤션 준수.
- S2 `Companion`(Node2D) 공통 FSM 3상태(ACQUIRE/ENGAGE/REPOSITION; RALLY/DOWNED/LOST enum만). 0.15s 결정 틱 + 매 프레임 이동. 근처 적만 해시 질의.
- S3 즉시판정 전투: 탱 근접·딜 원거리·카이팅(kite_min), 힐러 최저HP 아군(동료+자신, 무녀 제외) 회복. 관통2·투사체·정화는 계획대로 연기.
- S4 `EnemySystem.ally_targets` 동료 전환 + 도발 오버라이드(`get_taunt_radius()` 덕타이핑, 클래스 결합 회피) + `def_of()`(ELITE 우선순위).
- S5 separation(동료 겹침) + leash 고무줄(무녀 leash_radius 밖 복귀).
- S6 RunScene: 동료 3인 무녀 근처 스폰, ally_targets 등록, 무녀+동료 접촉피해, 디버그 라벨 동료 상태.
- S7 `companion_ai_check`(7 어서션) 전부 PASS.

## 검증 증거 (헤드리스)
- `companion_ai_check`: load/acquire_attack/kite/taunt/separation/leash/heal => 전부 PASS, VERDICT PASS.
- M1 회귀: move/spatial_query/enemy_pool/contact_damage/spawn_flow 전부 정상. main.tscn 120프레임 런타임 에러 0.

## 분기(divergence) — fg-learn 입력
- **D-a. 동료 틱 소유권 변경.** 계획은 "companion `_physics_process` 0.15s 누적 틱"이었으나, EnemySystem.tick과 동일하게 **RunScene이 `companion.step(dt)`로 구동**하도록 변경. 이유: 헤드리스 체크의 수동 스텝 결정성 + enemy/companion 틱 순서 일관(혼합 자동/수동 틱 회피). 기능 동일, 구동 위치만 이동.
- **D-b. 신규 class_name 등록에 import 패스 필요.** 헤드리스 첫 실행 전 `godot --headless --import`로 `Companion`/`CompanionDef` 전역 클래스 등록 필요(안 하면 "Could not find type" 파스 에러). 향후 신규 스크립트 추가 시 동일 — 체크 실행 전 import 1회.
- **D-c. spawn_flow_check(M1) 무수정 통과.** 적이 동료를 타겟하지만 동료가 무녀 근처(±80px) 스폰이라 적이 무녀 접촉 반경을 지나며 무녀 hp_drop 유지 → M1 어서션 그대로 PASS. 적 수 증가폭은 동료가 처치해 낮아짐(예상된 부수효과).
- **D-d. 타입 추론.** untyped `allies: Array` 순회에서 `:=` 추론 실패 2곳 → 명시 타입(`var ratio: float`, `var off: Vector2`)으로 수정.

## 비고
- 힐러 `attack_period`/`attack_range`는 def에 남되 attack_damage=0이라 미사용(데이터 일관성용).
- ELITE 우선순위 구현했으나 슬라이스엔 mob_low뿐이라 사실상 NEAREST 폴백(계획대로).

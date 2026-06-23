<!-- forge-slug: m3-mudang-levers -->
# run — M3 무녀 레버 4종 (계획 대비 실제)

실행: fg-loop 무인 드라이브(/goal 활성). 단일 에이전트 직접 구현(결합 슬라이스). 검증: 헤드리스 `mudang_levers_check`.

## 계획대로 된 것
- S1 Mudang 레버 파라미터 `@export`(오라/넉백/혼불/모여라/pickup, docs/01·09 시작값) + 카운터(mudang_exp/companion_soulfire_held). 런타임 상태(쿨다운/rally)는 RunScene 소유.
- S2 오라: EnemySystem.tick이 aura_center 반경 내 적 속도 ×slow_multiplier(거리검사, Area2D 미사용).
- S3 넉백: EnemySystem.apply_knockback(바깥 변위 ×(1-resist) + 0.15s 경직 SoA `_stun`, tick 이동 스킵). Mudang 파라미터 + RunScene 쿨다운/사거리 게이트 + aim 배선.
- S4 SoulfireSystem(신규 경량 풀): 자석 픽업(무녀혼불→EXP/동료혼불→보유) + 최근접 1동료 proximity-rate 전달(+0.5/량 회복, EXP 적립). EnemySystem.on_kill Callable 훅 → spawn_from_drop(DropTable 추첨).
- S5 모여라: RunScene rally 쿨다운(4s/18s) + Companion RALLY 분기(M2 enum 배선).
- S6 RunScene 통합(오라 주입→tick→넉백→동료 step→혼불 update→모여라, 디버그 라벨 확장).
- S7 mudang_levers_check 4종 PASS.

## 검증 증거 (헤드리스)
- mudang_levers_check: aura/knockback/soulfire/rally => 전부 PASS, VERDICT PASS.
- 회귀: companion_ai/spawn_flow/enemy_pool/contact_damage/spatial_query 전부 정상. main.tscn 200프레임 런타임 에러 0.

## 분기(divergence) — fg-learn 입력
- **D-a. 모여라 이동 모델 변경(add→override).** 계획/초안은 무녀 방향 가중 add였으나, 원거리 적 추격(engage vel 1.0×speed)을 0.9×bias add로는 못 이겨 실제 수렴이 안 됨 → RALLY 중 **이동을 무녀 방향으로 override**(공격은 engage 분기에서 이미 발사 = "교전 유지"). docs/01§5 "전투하며 서서히 모인다" 충족. RALLY_BIAS는 수렴 속도 비율로 의미 전환.
- **D-b. 드랍 훅 = Callable.** EnemySystem이 SoulfireSystem을 직접 모르게 `on_kill: Callable`로 디커플(시그널 대신 Callable — 노드 1:1, 단순). _kill에서 drop!=null일 때 호출.
- **D-c. 레버 런타임 상태 위치.** 쿨다운/rally 타이머는 Mudang이 아니라 RunScene(run-state) 소유, 파라미터만 Mudang(@export data). 헤드리스 결정성(수동 스텝) + 책임 분리.
- **D-d. 오라 레벨 보정 미구현(계획대로 M5).** mudang_lv 부재 → 단순 감속만.

## 비고
- 혼불 EXP(mudang_exp/companion_exp)는 카운터 적립만 — 레벨업/3택/보류카드 UI는 M5(계획대로 Non-goal).
- 넉백 쿨다운 게이트는 RunScene 로직이라 단위 체크 대신 통합(main)서 커버. 단위 체크는 변위/resist/경직에 집중.

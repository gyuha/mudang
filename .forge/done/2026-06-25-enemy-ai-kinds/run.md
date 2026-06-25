<!-- forge-slug: enemy-ai-kinds -->
# run — 적 AI 거동 분화: enemy_system이 ai_kind를 실제 사용
fg-loop 드라이브 task 24. eco on. 워크플로우 없이 직접 실행.

## 계획대로
- S1 enemy_ai_kind_check.gd+.tscn: 거점(근접30)+동료A(중100·고HP)+동료B(원-300·저HP) 배치(비탱 동료로 taunt 배제), ai_kind별 `_nearest_target` 타겟 검증 + rush_lowhp 적 tick 이동 방향 검증.
- S2 enemy_system `_nearest_target(from, def)`로 시그니처 확장 + ai_kind 분기: target_companion/ranged=최근접 동료(거점 무시), rush_lowhp=최저HP 동료, 그 외(rush_companion/elite/boss)=최근접 아군. 도발 오버라이드는 ai_kind 무관 최우선 유지. 헬퍼 `_nearest_ally_pos`/`_nearest_companion`/`_lowest_hp_companion`(Companion 타입 판별). tick 호출부 `_def[i]` 전달.
- S3 회귀: 전체 26체크 green, main 부팅 에러 0.

## 분기(divergence)
1. **elite/boss는 이동 분기만 존재, 거동은 rush_companion과 동일**: 현재 데이터(dokkaebi=elite, boss류)는 특수 이동이 없고 강함/느림은 수치로 표현됨. elite의 특수 거동·보스 페이즈는 계층② 후속(스코프 명시). 분기 자리는 만들어 둠.
2. **ranged 타게팅을 target_companion과 동일 처리**: ranged(mask_spirit)도 동료 우선 타게팅이 자연스러워 같은 분기에 묶음. 실제 원거리 공격 거동(정지+주기피해)은 task 25.
3. **_nearest_target 시그니처 변경(내부)**: 외부 공개 API 아님(tick 내부만 호출). 외부 호출처 없어 회귀 무영향.

## 검증
- enemy_ai_kind_check VERDICT => PASS: rush_companion→거점(30) · target_companion→동료A(100, 거점 무시) · rush_lowhp→저HP 동료B(-300) · tick에서 rush_lowhp 적 x<0(저HP 방향) 이동.
- 전체 회귀 26체크 FAIL 0 · SCRIPT_ERR 0 · main 부팅 에러 0.

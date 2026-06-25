<!-- forge-slug: purify-zone-objective -->
# run — purify_zone 목표 메커닉: 구역 점거 게이지 + 승리 경로 (계층②)
fg-loop 드라이브 task 26 (마지막). eco on. 워크플로우 없이 직접 실행.

## 계획대로
- S1 purify_zone_check.gd+.tscn(먼저): stage_yangban_gut 구동(해저드 제거+charge_time 단축으로 결정적) → 미점거 시 progress 0/NONE, 무녀 구역 점거 시 충전→만충→WIN 검증.
- S2 ObjectiveDef purify_zone params에 pos/radius 추가 + 데이터: stage4(1구역 pos(0,0) r200), stage5(3구역 분산 pos r180).
- S3 RunScene+ObjectiveEval purify 평가: `_purify_zones`(각 {pos,radius,charge_time,progress}) 등록, `_update_purify`가 매 틱 구역 내 아군(무녀/전투가능 동료) 점거 시 progress += dt/charge_time(상한 1), `_all_zones_purified` 전부 만충 시 승리. ObjectiveEval.evaluate에 has_purify/purify_done 추가(kill_boss 다음 우선, duration보다 우선).
- S4 회귀: 전체 29체크 green, main 부팅 에러 0.

## 분기(divergence)
1. **구역 지오메트리 데이터 신설**: 기존 purify_zone params는 {order, charge_time}뿐(구역 위치 없음) → pos(Vector2)/radius 추가. order는 표시용으로 보존(순차 잠금은 미구현 — 동시 충전 허용, 스코프 명시).
2. **purify 승리는 점거 완료가 트리거**(survive_time 병행 시 duration보다 우선) — kill_boss와 동일 패턴. 적의 역점령/감쇠는 후속.
3. **Dictionary Variant 타입 명시**: `z["pos"]`/`z["radius"]`가 Variant라 `:=` 추론 실패 → 지역변수로 명시 타입 받아 사용(GDScript 파스 요건).
4. **검증 결정성**: 실데이터(stage4) 사용하되 해저드 dps 제거 + charge_time 1.0 단축 + 무녀/동료 위치 직접 배치로 웨이브·해저드 교란 배제. 승패 조건 자체(점거 로직)는 본 변경으로 검증.

## 검증
- purify_zone_check VERDICT => PASS: 미점거 progress 0.000/result none · 점거 progress 1.000/result win · zones=1 geom_ok(pos/radius 데이터 반영).
- 전체 회귀 29체크 FAIL 0 · SCRIPT_ERR 0 · main 부팅 0 (stage456/wave_objective 등 무영향 — purify 없는 스테이지 unaffected).

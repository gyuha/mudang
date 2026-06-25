<!-- forge-slug: mobile-degrade-switch -->
# run — 모바일 열화 스위치: 동시 적 상한 동적 하향 (250)
fg-loop 드라이브 task 30 (마지막). eco on. 워크플로우 없이 직접 실행.

## 계획대로
- S1 mobile_degrade_check.gd+.tscn(먼저): active_limit=250 후 300 스폰→active 250 클램프 + low_spec ON/OFF 토글이 RunScene._enemies.active_limit(250/512)에 반영.
- S2 EnemySystem `var active_limit: int = CAP` + spawn 클램프 `_count >= min(CAP, active_limit)`.
- S3 GameState `low_spec: bool` + `MOBILE_ENEMY_CAP=250`. RunScene._ready에서 `_enemies.active_limit = MOBILE_ENEMY_CAP if low_spec else CAP`.
- S4 회귀 32체크 green, main 부팅 0.

## 분기(divergence)
1. **열화 노브는 동시 상한만(MVP)**: docs/06의 파티클 밀도↓·그림자/포스트 off·해상도 스케일은 해당 효과가 아직 없어(파티클/포스트 미존재) 후속. low_spec 플래그가 향후 그 분기들의 단일 진입점(자리 확보).
2. **기존 동작 무변경**: active_limit 기본=CAP라 min(CAP,CAP)=CAP — perf500(500)·enemy_pool(CAP 동적) 등 회귀 무영향 확인.
3. **플랫폼 자동감지/저장 미포함**: 수동 토글(GameState.low_spec)로 충분(설정 화면 UI·영속은 Non-goal).

## 검증
- mobile_degrade_check VERDICT => PASS: 직접 클램프 300→250 · low_spec ON→active_limit 250 · OFF→512.
- 전체 회귀 32체크 FAIL 0 · SCRIPT_ERR 0 · main 부팅 0.

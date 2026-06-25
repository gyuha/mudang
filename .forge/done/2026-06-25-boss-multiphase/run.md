<!-- forge-slug: boss-multiphase -->
# run — 보스 다페이즈 거동: HP 임계 페이즈 전환 (속도 escalation + 소환)
fg-loop 드라이브 task 29. eco on. 워크플로우 없이 직접 실행.

## 계획대로
- S1 boss_multiphase_check.gd+.tscn(먼저): 보스+더미타겟 배치. 만HP 1틱 이동량 vs HP 30%(페이즈2) 1틱 이동량 비교(저HP가 큼) + 66%/33% 임계 하향 시 active_count가 소환만큼 증가.
- S2 EnemyDef `summon_id`/`summon_count` 필드 + 보스 데이터: boss_royal_wraith(mob_low ×4), boss_tiger(changgwi ×3).
- S3 enemy_system `_phase` SoA(spawn/kill swap) + boss 분기: tick에서 hp_ratio로 페이즈(>=66%→0, >=33%→1, else 2) 산출, 속도 ×(1+0.25×phase), 페이즈 하향 전환 1회 `_boss_summon`(보스 주변 분산 spawn). boss_multiphase_check PASS.
- S4 회귀 31체크 green, main 부팅 0.

## 분기(divergence)
1. **소환은 tick 중 spawn — 현재 틱 루프 비확장**: `for i in _count`는 _count를 루프 시작 시 1회 평가하므로 spawn으로 추가된 미니언은 이번 틱에 처리 안 됨(인덱스 시프트 없음 — append만). 안전.
2. **다페이즈 = 속도 escalation + 전환 소환(MVP)**: 고유 광역저주/투사체 패턴은 연출·M8 후속(스코프 명시). 페이즈 임계는 66%/33% 고정(데이터화는 후속).
3. **1샷 처치는 소환 안 함**: 페이즈는 tick에서 평가 — stage456/stage3가 apply_damage(99999)로 1샷 처치 시 tick 재평가 전에 죽어 소환 없이 WIN(기존 보스 처치 경로 무파손, 회귀 31 green 확인).

## 검증
- boss_multiphase_check VERDICT => PASS: 만HP 이동 5.20 → 저HP(p2) 7.80(1.5배 escalation) · 임계 전환 소환 active 1→5(+4=summon_count).
- 전체 회귀 31체크 FAIL 0 · SCRIPT_ERR 0 · main 부팅 0.

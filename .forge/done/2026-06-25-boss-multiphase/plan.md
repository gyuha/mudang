<!-- forge-slug: boss-multiphase -->
<!-- task: 29 -->
<!-- tdd: off -->
<!-- priority: high -->
<!-- generated-by: fg-loop -->
# 보스 다페이즈 거동 — HP 임계값 페이즈 전환 (속도 escalation + 소환)

## Goal / Non-goals
- Goal: `ai_kind=boss` 적이 HP 비율 임계값(예 66%/33%)을 넘을 때 페이즈가 올라가며 거동이 강해진다. (a) 저HP 페이즈에서 이동속도 상승(escalation), (b) 임계 전환 시 1회 소환(잡몹 K마리)으로 압박 증가. 스테이지 6 "3페이즈 보스"의 기계적 실체.
- Non-goals: 고유 광역저주/투사체 패턴(연출·M8 후속), 페이즈별 전용 애니/연출, 보스 UI(페이즈 바). 넉백 면역 토글(데이터 knockback_resist로 충분).

## Source of truth
- Glossary terms: boss(ai_kind), 다페이즈 in .forge/CONTEXT.md
- Related ADRs: docs/10(스테이지6 3페이즈 보스), docs/04 §1(boss 거동), docs/09
- Definition of Done: boss_multiphase_check가 `VERDICT => PASS` — 저HP 보스가 만HP 보스보다 빠르게 이동(속도 escalation) AND HP 임계 전환 시 active_count 증가(소환). 회귀 무파손.

## 설계 메모
- enemy_system: 보스 페이즈 추적용 SoA `_phase: PackedInt32Array`(spawn 0, kill swap). tick의 boss 분기에서 hp_ratio=_hp[i]/_def[i].max_hp로 목표 페이즈 계산(>=66% p0, >=33% p1, else p2). 이동속도 = move_speed × (1 + 0.25×phase). _phase[i] < 목표면 전환: _phase[i]=목표, 소환(summon).
- EnemyDef에 소환 필드: `summon_id: StringName`(예 mob_low), `summon_count: int`(예 3). 보스 def에 설정. 소환은 self.spawn(load(summon_id), 보스 근처 분산)로 K마리.
- 소환은 페이즈 전환 1회만(_phase 갱신으로 가드) — 매 틱 소환 금지.
- 보스 이동 타겟은 기존 boss 분기(최근접 아군) 유지.

## Work slices
- [ ] S1. tools/test/boss_multiphase_check.gd+.tscn(먼저): 보스 1마리 + 타겟 배치. (1) 만HP에서 1틱 이동량 vs HP 30%로 깎은 뒤 1틱 이동량 비교(저HP가 더 큼). (2) HP를 66% 임계 아래로 깎고 1틱 → active_count가 소환만큼 증가. 미구현 시 FAIL.
- [ ] S2. EnemyDef summon_id/summon_count 필드 + 보스 .tres(최소 boss_royal_wraith·boss_tiger)에 설정.
- [ ] S3. enemy_system `_phase` SoA + boss 페이즈 거동(속도 escalation + 전환 시 소환). boss_multiphase_check PASS.
- [ ] S4. 회귀 무파손: 기존 체크 green(특히 stage3/stage456 보스 처치 경로, perf500), main 부팅 0.

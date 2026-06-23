<!-- forge-slug: m4-care-downed-revive -->
# run — M4 케어 (계획 대비 실제)

실행: fg-loop 무인 드라이브. 직접 구현. 검증: 헤드리스 `care_check`.

## 계획대로 된 것
- S1 쓰러짐: Companion `take_contact_damage` hp<=0 → `_enter_downed()`(DOWNED, downed_timer 8s). DOWNED/LOST 무적·정지, step()서 타이머 감소 → 0이면 LOST. is_downed/is_lost/is_incapacitated 헬퍼.
- S2 부활: `revive_progress(dt, channel_time)`(충전 완료 시 hp=max×0.4 + ACQUIRE) / `revive_decay`(이탈 감쇠). Mudang revive_range=100/revive_channel_time=3.0 @export.
- S3 RunScene: 매 프레임 ally_targets를 전투가능 동료만으로 재구성(쓰러진 동료 적 타겟 제외), 무녀 정지+근접 최근접 DOWNED 채널/그 외 감쇠.
- S4 상실 디버프: LOST 수 → SoulfireSystem.pickup_efficiency=max(0.4,1-0.15*lost)로 혼불 흡수량↓. 화력 감소는 동료 이탈로 자동.
- S5 care_check 5종(downed/lost/revive/decay/lost_debuff) PASS.

## 검증 증거 (헤드리스)
- care_check 5/5 PASS. 회귀: mudang_levers/companion_ai/spawn_flow/enemy_pool/contact_damage 정상. main.tscn 200프레임 런타임 에러 0.

## 분기(divergence)
- 없음(계획대로). downed_timer/revive 파라미터는 docs/02 시작값. 연출(머리 위 링/미니맵)은 계획대로 M8 Non-goal — 헤드리스는 타이머/상태/게이지 로직만 검증.
- 상실 디버프 magnitude(-15%/lost, 하한 0.4)는 임의 시작값 — M8 밸런스 튜닝 대상.

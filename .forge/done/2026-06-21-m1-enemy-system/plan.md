<!-- forge-slug: m1-enemy-system -->
<!-- task: 2 -->
<!-- tdd: off -->
# M1 — EnemySystem API + 단순 백엔드 + 잡귀 스폰/추격/접촉피해

## Goal / Non-goals
- Goal: M0 RunScene 위에 **EnemySystem**을 세운다 — docs/11 §1 API 경계(`spawn`/`query_circle`/`position_of`/`apply_damage`)를 고정하고, **단순 풀링 백엔드(~150)** + **균일 격자 SpatialHash**로 구동. 잡귀(mob_low)가 **배치된 스폰 포인트(우물 상시 + 갈라진 땅 시간차 개방, D24)**에서 솟아 **가장 가까운 아군 타겟(M1=무녀)**으로 직진하고, 접촉 시 **무녀 HP(D6-a, 100)**를 `contact_damage`/s로 깎는다.
- Non-goals: 동료/무사(M2) · 데이터 주도 WaveDirector·StageDef 스폰 배치(M6) · SoA+MultiMesh 스케일업(M-S, ~150 넘기지 않음) · 잡귀 외 적종·보스 · 거점/목표 · 패배 화면(HP 0은 로그/리셋 정도) · 넉백/오라(M3).

## Source of truth
- 설계 권위(docs/): `docs/04`(스폰 포인트 모델 D24·EnemyDef·접촉피해=초당), `docs/06`§1·§2(단순 백엔드→후속 MultiMesh 교체, SpatialHash 물리없음), `docs/11`§1(EnemySystem API: query_circle/apply_damage/position_of), `docs/01`§7·`docs/00` D6-a(무녀 HP 100·접촉 피해), `docs/09`§0·§2(무녀 HP/이동, mob_low 6HP·속도70·접촉4·exp1).
- 기존 코드/데이터: M0 산출물(`scripts/run_scene.gd` RunScene·`scripts/actors/mudang.gd`·`scripts/autoload/input_adapter.gd`·`scripts/bg_grid.gd`), `data/enemies/mob_low.tres`(+ `scripts/data/enemy_def.gd`/`drop_table.gd`).
- 회고 반영(`.forge/retro/2026-06-21-m0-project-skeleton.md`): 월드 고정 기준은 BgGrid로 이미 충족(적 이동 가시) · **새 `class_name` 추가 후 헤드리스 실행 전 `godot --headless --import` 필수** · GUI 검증과 헤드리스 로직 검증 분리(가능한 로직은 헤드리스 단언).
- Related ADRs: none (결정은 docs/00 D6-a·D19·D24).
- Definition of Done: Godot GUI에서 — 무녀가 격자 위를 움직이는 동안 **우물/갈라진 땅에서 잡귀가 솟아 무녀로 몰려오고**, 시간이 지나면 **크랙이 추가 개방**돼 스폰이 늘며, **접촉 시 무녀 HP 라벨이 감소**. + 헤드리스 로직 체크(스폰 상한·query_circle·apply_damage·접촉피해) 통과. (시각·체감은 GUI, 로직은 헤드리스 — 둘 다 사람 실행 필요분 포함)

## Work slices
- [ ] S1. **EnemySystem + 단순 풀링 백엔드(~150 상한)** — API `spawn(def,pos)`/`query_circle(c,r)→ids`/`position_of(id)`/`apply_damage(id,amt)`(HP≤0 시 풀 슬롯 swap-remove 회수), 잡귀=ColorRect 플레이스홀더, `mob_low.tres` 로드. 완료 기준(헤드리스): N개 spawn 후 active_count==min(N,150) 상한 클램프, apply_damage로 HP0 처치 시 슬롯 회수 — `tools/test/` 던지는 체크로 단언.
- [ ] S2. **균일 격자 SpatialHash + query_circle 연결** — 매 틱 재구축, 반경 내 적 id 반환(물리/Area2D 미사용, docs/06§2). 완료 기준(헤드리스): 알려진 좌표로 적 배치 시 `query_circle` 결과가 기대 집합과 일치(반경 안/밖 경계 포함). (depends: S1)
- [ ] S3. **잡귀 추격(가장 가까운 아군 타겟 직진) + 무녀 접촉 피해** — 적이 매 틱 nearest ally-target(M1=무녀, 로직은 무사 확장 가능하게 "아군 타겟 목록"으로) 방향 이동, 무녀 주변 query_circle로 접촉 적 판정 → `contact_damage`(4)/s로 무녀 HP 감소. 무녀 HP(100) + HP를 디버그 라벨에 표시. 완료 기준(헤드리스): 적을 무녀 인접에 두고 1s 진행 시 무녀 HP가 접촉 적 수×contact_damage 만큼 감소. (depends: S1,S2)
- [ ] S4. **스폰 포인트(우물 상시 + 크랙 시간차 개방) 하드코딩 + 솟는 간이 연출** — RunScene에 우물 2~3 + 크랙 몇 개(플레이스홀더 표시) 배치, 간단 타이머로 크랙 추가 개방, 활성 포인트에서 잡귀를 상한까지 솟게(짧은 등장 연출/딜레이). 데이터 주도 배치는 M6 Non-goal. 완료 기준(GUI): 잡귀가 포인트에서 솟아 무녀로 몰려오고, 시간 경과 시 크랙이 추가로 열리며, 접촉 시 무녀 HP 라벨이 줄어든다. (depends: S3)

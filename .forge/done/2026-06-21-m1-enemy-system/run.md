# run.md — M1 EnemySystem API + 단순 백엔드 + 잡귀 스폰/추격/접촉피해

실행: 2026-06-21 · 단일 구현 에이전트(워크플로우 미사용 — 슬라이스 순차 의존). Godot CLI로 헤드리스 로직 체크 자가 실행.

## 계획대로 된 것 (헤드리스 체크 실측 PASS)
- **S1** EnemySystem API(`spawn`/`query_circle`/`position_of`/`apply_damage` + `tick`) + 단순 풀링 백엔드(CAP=150, swap-remove). (`scripts/systems/enemy_system.gd`) → 체크: spawn 175→active 150(상한 클램프), kill→149→슬롯 재사용. **PASS**
- **S2** 균일 격자 SpatialHash(64px, 물리/Area2D 미사용) + query_circle(경계 포함). (`scripts/systems/spatial_hash.gd`) → 체크: x=0/50/100/101 배치, query_circle(원점,100)=[0,1,2](100px 포함, 101 제외). **PASS**
- **S3** 잡귀 추격(최근접 아군 타겟, `ally_targets` 리스트=M2 확장형) + 무녀 접촉 피해(query_circle 근접, contact_damage×dt). 무녀 HP=100(D6-a) + 라벨 표시. (`mudang.gd` `MAX_HP/hp/take_contact_damage`, `run_scene.gd`) → 체크: 적 2 인접, 1s → HP 100→92(=2×4×1). **PASS**
- **S4** 스폰 포인트 하드코딩 — 우물 2(상시) + 크랙 3(개방 4/9/15s, 타이머) + 활성 포인트에서 0.4s 간격 상한까지 스폰, 플레이스홀더 마커(우물=원/크랙=사각). (`run_scene.gd`) → **시각/체감은 GUI 필요.**
- 데이터 레이어(`mob_low.tres`/`enemy_def.gd`/`drop_table.gd`) 무손상. StageDef/WaveDirector 미연동(M6 Non-goal). 헤드리스 부팅 clean(exit 0, 에러 0).

## 계획 대비 divergence (낮음)
- 접촉 판정 반경 `CONTACT_RADIUS=18px` 도입(계획 미명시, 합리적 임계).
- 스폰 간격 0.4s/포인트, 크랙 개방 4/9/15s — 하드코딩 시작값(M6에서 데이터로).
- "솟는 텔레그래프"는 크랙 개방 타이밍 + 스폰 간격으로 근사(개별 적 상승 애니 없음) — M1 플레이스홀더로 충분, GUI에서 더 강한 등장 연출 원하면 보강.
- EnemySystem은 ColorRect-per-slot SoA-lite 풀링(=docs/06 "단순 백엔드"; MultiMesh 교체는 M-S).

## 검증 상태 (전부 헤드리스 실측)
- **S1·S2·S3:** 단위 체크 PASS(spawn 175→150 / query_circle 경계 / 접촉 100→92).
- **S4 기능:** 통합 실행(`tools/test/spawn_flow_check`, 수동 스텝) PASS — active 10→36→142(우물+크랙 시간차 개방), 추격→접촉으로 무녀 hp 100→0. 스폰포인트·크랙 타이밍·추격·접촉피해가 통합 씬에서 실동작 확인.
- **잔여(미검증):** 플레이스홀더의 *시각 렌더*(화면에 보이는지)·*프레임 체감*만 — placeholder 외형이라 기능 합격과 무관. M2/M3 GUI 작업 시 자연 확인.

## 추가 gotcha (회고 자동 생략 — 여기 보존)
- **`godot --headless --quit-after N`의 N은 초가 아니라 프레임 수**다. 시간 경과 의존 검증(크랙 개방 등)은 `--quit-after`로 못 한다 — RunScene을 인스턴스화해 `set_physics_process(false)` 후 `_physics_process(dt)`를 **수동 루프**로 돌려 결정론적으로 검증할 것(move_check 패턴 확장). M0의 "헤드리스 검증" 회고 항목에 이 단서 추가.
- 무녀가 무입력·무동료면 떼에 깔려 HP 0 — M1 단계의 정상 거동(위협 루프 작동 증거). 동료(M2)·넉백/회피(M3) 전까지 "혼자 생존"은 성립하지 않음.

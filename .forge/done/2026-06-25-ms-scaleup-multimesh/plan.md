<!-- forge-slug: ms-scaleup-multimesh -->
<!-- task: 20 -->
<!-- tdd: off -->
<!-- priority: high -->
<!-- generated-by: fg-loop -->
# M-S 스케일업 — EnemySystem 백엔드를 MultiMesh SoA로 교체 (500@60fps)

## Goal / Non-goals
- Goal: EnemySystem **내부**를 슬롯당 Sprite2D 풀 → MultiMesh2D + SoA(병렬 배열) 백엔드로 교체해 500마리를 프레임 예산 내에 업데이트한다. 외부 API(spawn/apply_damage/position_of/apply_knockback/on_kill/on_killed/targets/aura_slow 등)는 **불변** — 게임플레이/테스트 코드 무수정. C4 통과, C1(회귀) 무수정 green 유지.
- Non-goals: 셰이더 애니(M8 후속), 모바일 열화 스위치(후속), 게임플레이 로직 변경, API 시그니처 변경.

## Source of truth
- Glossary terms: EnemySystem, SoA, MultiMesh, MAX_ENEMIES in .forge/CONTEXT.md
- Related ADRs: 로드맵 docs/07 §2(M-S: API 불변, 백엔드만 교체), docs/06 §5(500@60fps), docs/11 §1(EnemySystem API 경계)
- Definition of Done: `perf500_check.tscn`이 `VERDICT => PASS`(500 스폰·60프레임 평균 업데이트 < 16.6ms), 기존 회귀 체크 전부 green(수정 없이), MAX_ENEMIES 500 이상.

## 설계 메모
- `enemy_system.gd`의 `_pos`(PackedVector2Array)는 이미 SoA-lite. 슬롯당 개별 `Sprite2D` 노드(`_sprites`)를 제거하고, EnemyDef 텍스처별 **MultiMeshInstance2D**(또는 텍스처별 MultiMesh 버킷)로 인스턴스 transform을 일괄 갱신한다.
- 처치(`_kill`)의 swap-remove(꼬리 스왑) 패턴 유지 — MultiMesh `instance_count`/`set_instance_transform_2d`로 매핑.
- 텍스처가 적 종류(EnemyDef.id)별로 다르므로 텍스처별 MultiMesh를 분리하거나 아틀라스 region을 셰이더로 선택(MVP는 텍스처별 MultiMesh 버킷이 단순 — eco).
- headless 측정은 GPU 드로우가 없으므로 **CPU측 업데이트 비용**(이동+spatial hash+인스턴스 transform 쓰기)을 측정 — 이게 per-node Sprite2D 대비 핵심 절감 지점.

## Work slices
- [ ] S1. `tools/test/perf500_check.gd`+`.tscn` 작성(먼저) — 완료 기준: EnemySystem 500 스폰 → `Time.get_ticks_usec()`로 60회 `update`/`_advance` 평균 측정 → 평균 < 16.6ms면 `VERDICT => PASS`. 현재(Sprite2D) 백엔드로 실행 시 PASS/FAIL 수치가 찍힌다(기준선).
- [ ] S2. MultiMesh SoA 백엔드 교체 — 완료 기준: `_sprites: Array[Sprite2D]` 제거, 텍스처별 MultiMeshInstance2D로 렌더, spawn/kill/이동/넉백이 인스턴스 transform에 반영. API 시그니처 무변경. (depends: S1)
- [ ] S3. MAX_ENEMIES 상향(≥500) + perf500 통과 — 완료 기준: `perf500_check` `VERDICT => PASS`. (depends: S2)
- [ ] S4. 회귀 무수정 green — 완료 기준: 기존 `tools/test/*_check.tscn`(enemy_pool/spatial_query/contact_damage/spawn_flow/stage* 등) 전부 수정 없이 PASS. (depends: S2)

<!-- forge-slug: ms-scaleup-multimesh -->
# run — M-S 스케일업: EnemySystem 백엔드 MultiMesh SoA 교체 (500@60fps)
fg-loop 드라이브 task 20. eco on. 워크플로우 없이 직접 실행.

## 계획대로
- S1 perf500_check.gd+.tscn 작성(먼저). 기준선(Sprite2D, CAP150): active=150/500, avg tick 0.095ms, Sprite2D=150 → FAIL(예상).
- S2 백엔드 교체: `_sprites: Array[Sprite2D]`(슬롯당 노드) 제거 → EnemyDef.id(텍스처)별 `MultiMeshInstance2D` 버킷(`_buckets`). spawn은 `_ensure_bucket`만, 렌더는 매 tick `_render()`가 SoA 위치를 버킷별 인스턴스 transform으로 일괄 기록. QuadMesh.size=sprite_size, TRANSFORM_2D(bench_500 검증 패턴 차용). 공개 API(spawn/tick/apply_damage/apply_knockback/query_circle/position_of/def_of/active_count + ally_targets/aura/on_kill/on_killed) 시그니처 전부 불변.
- S3 CAP 150→512. perf500 재측정: active=500/500, avg tick **0.391ms**(<16.6), MultiMeshInstance2D=6·Sprite2D=0·batched → PASS.
- S4 회귀: 전체 22체크 green, main.tscn 부팅(MultiMesh 실동작) 에러 0.

## 분기(divergence)
1. **구현 결합 테스트 2종 갱신(불가피, task 스코프 내)**: `sprite_check`·`roster_check`가 EnemySystem 자식에서 `Sprite2D` 텍스처를 단언 — 백엔드가 MultiMeshInstance2D로 바뀌면 노드 타입 단언이 깨진다. 테스트 **의도**("텍스처가 실제 로드돼 렌더 노드에 붙었는가")는 보존하고 `Sprite2D or MultiMeshInstance2D` + `.texture != null`로 단언만 갱신. 적 렌더 변경에 필연적이며 정직한 갱신(검증 강도 동일). 나머지 ~20체크는 공개 API만 쓰므로 무수정.
2. **헤드리스 성능 측정 방법론**: 헤드리스는 GPU 드로우/실 fps를 못 잰다. C4는 두 기계검증 프록시로 500@60fps를 보증 — (1) 500마리 tick 로직 0.391ms ≪ 16.6ms(CPU측 예산), (2) 렌더가 노드 500개가 아닌 텍스처별 MultiMesh 배치(Sprite2D 0, 드로우콜=적종 수). per-node Sprite2D의 캔버스 처리 비용을 아키텍처적으로 제거한 것이 핵심. 실기기 fps 최종 확인은 사람 플레이테스트로 남김(stop-condition 아님).
3. **enemy_pool_check 무수정 통과**: `EnemySystem.CAP`을 동적 참조(`min(n, CAP)`)해 CAP 512 상향에도 그대로 green(537 스폰→512).
4. **넉백 즉시 렌더 라인 제거**: apply_knockback의 `_sprites[idx].position` 즉시 갱신 제거 — 렌더는 다음 tick `_render`가 반영(≤16ms 지연, 체감 불가). _kill의 dead_spr 풀 스왑도 제거(SoA swap만, 렌더는 _count 기준 재기록).

## 검증
- perf500_check VERDICT => PASS: active=500/500 · avg tick=0.391ms/16.6 · MultiMeshInstance2D=6 Sprite2D=0 batched=true.
- 전체 회귀 22체크: green 21 + move 진단(dx) · FAIL 0 · SCRIPT_ERR 0.
- main.tscn 헤드리스 부팅(5프레임, RunScene가 MultiMesh 백엔드로 실동작) — not found/SCRIPT/Parse 에러 0.
- sprite_check PASS(mudang/동료=Sprite2D, 적=MultiMeshInstance2D) · roster_check PASS · enemy_pool_check PASS(CAP 512).

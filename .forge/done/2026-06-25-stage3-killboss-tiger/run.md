<!-- forge-slug: stage3-killboss-tiger -->
# run — 스테이지 3 산길의 창귀 + kill_boss 평가 (데이터 축)
fg-loop replan round 1 fix-forward (C2 완결 + C3 전진). eco on. 워크플로우 없이 직접 실행(소규모).

## 계획대로
- S1 kill_boss 평가: EnemySystem `on_killed(def)` 훅 추가(기존 `on_kill` 불변) → RunScene `_kill_boss_targets`(id→처치) 추적 → `ObjectiveEval.evaluate`에 kill_boss 분기(기본인자, 기존 4-arg 호출 무손상). kill_boss 스테이지는 보스 처치만이 승리(duration 트리거 아님).
- S2 boss_tiger: EnemyDef .tres(HP720/resist0.85/contact20/ai_kind=boss/sprite150). 스프라이트 codex-image 생성(호랑이 요괴, 1024², 투명).
- S3 stage_mountain_pass.tres: kill_boss(boss_tiger) + purify_zone(예약 stub) + 창귀/잡귀 테마 + 보스 타임라인(t=150) + 활잡이 해금 + unlock_requires=2장.
- S4 stage3_check + 회귀: stage3_check PASS(eval none/win/lose 단위 + validate + 보스추적 + 생존중 NONE + 처치시 WIN). 회귀 18종 green, main(1장) 파스 에러 0.

## 분기(divergence)
1. **기존 회귀 손상 발견·수정**: `tools/test/spawn_flow_check.gd:27`이 `rs._stronghold`(단수)를 참조해 이미 깨져 있었음 — stage2(task#16) 단일→다중 거점 리팩터가 남긴 손상(자동 스킵 회고가 놓침). `git show HEAD`로 내 변경 이전부터 깨진 것 확인. C4(회귀 green)가 정지조건이라 1줄 기계적 수정(`_strongholds[0]`) 후 재검증 PASS. **내 작업이 깨뜨린 것 아님.**
2. **codex-image 백그라운드 행**: 백그라운드(harness)로 돌린 `codex exec`는 출력·이미지 없이 멈춤/실패 반복. **포그라운드 codex exec만 정상 동작**. 포그라운드 재시도로 스프라이트 생성 성공. (다음엔 codex-image는 포그라운드로.)
3. **purify_zone = 예약 stub**: 3장 목표에 데이터로 존재하나 평가 엔진 미구현(점거게이지=스코프外 예약). kill_boss가 승리 트리거라 스테이지는 플레이/검증 성립. 엔진 안착 시 evaluate가 양쪽 요구하도록 확장.
4. **3장 배경/인트로 일러스트 미생성**(eco, Non-goal): 배경은 폴백(stage1 bg/BgGrid), 인트로는 텍스트 전용 카드. 시야제한(global_rule) = StageModifier 클래스 미존재로 null 예약. → 아트/엔진 후속.

## 검증
- stage3_check: eval(none_alive/win_dead/lose_mudang) + data(validate/kill_boss=boss_tiger/purify_stub) + run(보스추적/생존중 NONE/처치시 WIN) 전부 PASS.
- 회귀 18종 green(move_check은 PASS 문구 없는 진단 테스트, dx=110 일치). main 파스/임포트 에러 0. boss_tiger.png 임포트 정상.

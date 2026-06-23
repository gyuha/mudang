<!-- forge-slug: art-enemy-bg -->
<!-- task: 11 -->
<!-- tdd: off -->
# 적/보스 스프라이트 + 배경 아트

## Goal / Non-goals
- Goal: codex-image로 적4(잡귀/처녀귀신/도깨비/보스) 투명 스프라이트 + 아레나 배경 생성 → EnemySystem 풀을 Sprite2D(id별 텍스처)로, RunScene 배경 적용. (docs/08)
- Non-goals: 잡몹 MultiMesh+아틀라스(M-S), 애니 프레임, 시각 품질(GUI/사용자).

## Definition of Done
- assets/sprites/{mob_low,ghost_maiden,dokkaebi,boss_hwalinseo}.png + assets/bg/stage_hwalinseo.png 존재, sprite_check(적 포함) PASS, 회귀 green, main 에러 0.

## Work slices
- [x] S1. codex-image로 적4 투명 스프라이트 + 배경 1 생성
- [x] S2. EnemyDef.sprite_size 추가 + 4 tres 설정(mob28/ghost36/dokkaebi72/boss160)
- [x] S3. EnemySystem 풀 ColorRect→Sprite2D(중심정렬, def별 텍스처/스케일), RunScene 배경 스프라이트(BgGrid 폴백)
- [x] S4. sprite_check 적 검사 추가 + 회귀

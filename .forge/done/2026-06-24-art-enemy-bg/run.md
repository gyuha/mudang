<!-- forge-slug: art-enemy-bg -->
# run — 적/보스 스프라이트 + 배경

실행: fg-loop(/goal), eco on. codex-image 생성 + 직접 와이어링.

## 계획대로
- S1 적4 투명 RGBA + 배경(불투명 탑다운 지면) 생성.
- S2 EnemyDef.sprite_size(@export) + 4 tres(mob 기본28/ghost36/dokkaebi72/boss160).
- S3 EnemySystem 풀 Sprite2D화: _apply_sprite(def.id 텍스처, sprite_size 스케일, 중심정렬), spawn/tick/knockback/kill 중심좌표로. RunScene 배경 Sprite2D(1600px 커버, BgGrid 폴백).
- S4 sprite_check에 적 스폰 텍스처 검사 추가.

## 검증
- sprite_check: 무녀+동료3+적(mob) 전부 Sprite2D+텍스처 PASS. 회귀 13종 green, main 220프레임 에러 0, import 파스 에러 0.
- 시각 적합성(스프라이트 스케일/배경 톤)은 GUI 확인.

## 분기
- 잡몹도 개별 Sprite2D(docs/08은 호드=MultiMesh+아틀라스 권장) — ~150엔 충분, 500 스케일은 M-S 후속.
- PLACEHOLDER_SIZE 상수 제거(적 시각이 Sprite2D로 전환되며 미사용 — 내 변경이 만든 orphan 정리).

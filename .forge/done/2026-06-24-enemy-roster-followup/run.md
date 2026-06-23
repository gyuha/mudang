<!-- forge-slug: enemy-roster-followup -->
# run — 후속 적 로스터
fg-loop(/goal), eco on. codex-image + 데이터 저작.
## 계획대로
- 창귀(HP18/속150/rush_lowhp)·역병귀(25/60)·탈귀(20/55/ranged) EnemyDef + DropTable + sprite_size + 투명 스프라이트.
## 검증
- roster_check: 3종 로드/스탯(docs/04§1)/스폰/스프라이트 PASS. import 파스 에러 0.
## 분기
- 특수 거동(돌진 가속·독 장판·원거리 저주)은 미구현 = 예약(D22 계층②/엔진). 데이터 축으로 스폰·이동·접촉만 성립(docs/10 "데이터 축만으로 성립").

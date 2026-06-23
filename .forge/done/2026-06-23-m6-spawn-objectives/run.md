<!-- forge-slug: m6-spawn-objectives -->
# run — M6 스폰·목표 (계획 대비 실제)

실행: fg-loop 무인 드라이브(/goal). 직접 구현. 검증: 헤드리스 `wave_objective_check` + 통합 smoke.

## 계획대로 된 것
- S1 WaveDirector: 타임라인 채널(정시 1회 발동) + 예산 채널(budget_per_sec 누적 → 활성 풀 가중추첨, spawn_cost 소비, max_active 클램프). 스폰포인트 라운드로빈.
- S2 Stronghold(거점 HP300): ally_targets 포함, 접촉피해 수용, is_destroyed.
- S3 ObjectiveEval.evaluate 순수 함수(무녀/거점 사망=lose, duration=win, else none).
- S4 RunScene: stage_hwalinseo.tres 로드, 하드코딩 스폰 제거→WaveDirector, 거점 중앙 배치, 적별 contact_damage 합산(혼재 대응), 매 프레임 결과 평가→GameState RESULT 전이+시뮬 정지. 디버그 라벨에 거점HP/결과.
- S5 wave_objective_check 3종 PASS.

## 검증 증거 (헤드리스)
- wave_objective_check 3/3 PASS(예산스폰+타임라인 발동 / 거점 피해·파괴 / 승패 4분기). 전 10종 회귀 green. main.tscn 300프레임 script error 0.
- **이제 `main.tscn` = 완전한 6분 슬라이스**: 데이터 주도 웨이브(잡귀/처녀귀신/도깨비/보스 타임라인) + 동료 자율전투 + 무녀 4레버 + 케어/부활 + 성장(auto-pick) + 거점 방어 + 승/패.

## 분기(divergence)
- **D-a. spawn_flow_check(M1) 갱신.** M6가 적 타게팅을 동료/거점으로 바꿔(무녀 비타겟) M1의 무녀 hp_drop·단조증가 어서션이 낡음 → 통합 스모크로 재정의(스폰 발생 + 적 거점 접근 + 헛된 승패 없음). 내 변경이 만든 정리.
- **D-b. 접촉피해 정밀화.** mob_low 고정값 → 적별 def_of(idx).contact_damage 합산(M6 혼재 적). M1 근사 개선.
- **D-c. 크랙 시간차 개방 제거.** M1 페이싱 → M6 타임라인/예산 페이싱으로 대체(스폰 포인트는 위치만 유지).
- **D-d. 거점 타겟 비율(20%/40% docs/09§3) 미세조정 안 함.** 거점을 ally_target에 포함(최근접) — 비율 정밀화는 M8 밸런스.

## 비고 — 헤드리스 가능 게임플레이 마일스톤 소진
- M3·M4·M5로직·M6 완료 = 헤드리스로 만들고 검증 가능한 게임플레이 backbone 전부. 남은 건 GUI/체감/밸런스/플레이테스트 = human only(아래 loop.md wall).

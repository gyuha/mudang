<!-- forge-slug: shell-loadout-result -->
# run — 메타 셸 ②: 편성(로드아웃) + 결과 화면
fg-loop 드라이브 task 22. eco on. 워크플로우 없이 직접 실행.

## 계획대로
- GameState 확장: `selected_companions: Array[String]`(편성 출력, 비면 RunScene 기본 풀 폴백) + `last_result: StringName`(런→결과 통로).
- S1 `scripts/ui/loadout.gd`(class_name Loadout extends Control): BASE_COMPANIONS 3종 + 해금 추가분 → `available_companions()`, `toggle_companion`(slot=meta.loadout_slots=2 상한), `confirm()`(1명 이상 시 selected→GameState.selected_companions + RUN 전이).
- S2 RunScene `_spawn_companions` 편성 소비: `GameState.selected_companions` 있으면 그 동료들, 없으면 COMPANION_PATHS 폴백. 오프셋 `i % size`로 슬롯 가변 대응.
- S3 `scripts/ui/result.gd`(class_name Result extends Control): `GameState.last_result` 읽어 표시(`result_text`), 메타 저장은 RunScene가 승리 시 이미 1회(중복 없음), `to_dashboard()` → DASHBOARD 전이. RunScene는 RESULT 전이 시 `GameState.last_result=_result` 기록.

## 분기(divergence)
1. **.tscn 미생성(스타일 일치)**: dashboard와 동일하게 코드 빌드 class_name(`.new()` 인스턴스화), 별도 .tscn 없음.
2. **기본 풀 3종은 항상 출전 가능**: unlocked_companions는 추가 동료 확장용(docs/12 예약). 슬라이스 3종(화랑/활잡이/견습)은 BASE_COMPANIONS로 상시 노출 — 신규 메타에서도 편성 가능.
3. **GameState.last_result 통로 추가**: RunScene는 RESULT 전이로 제거되므로 결과값을 GameState 경유로 Result에 전달(런↔화면 결합 최소).

## 검증
- loadout_result_check VERDICT => PASS:
  - loadout: avail=3 · 2선택 · 3번째 슬롯가득 거부 · confirm=true · state=RUN · selected_companions=2.
  - RunScene 편성 소비: 동료 2인 스폰(편성=2).
  - result: 승리 텍스트 표시 · to_dashboard → DASHBOARD 전이.
- 전체 회귀 24체크 FAIL 0 · SCRIPT_ERR 0 (RunScene 변경이 stage*/spawn_flow/wave 등에 무영향, 폴백 동일).
- main.tscn 부팅 에러 0.

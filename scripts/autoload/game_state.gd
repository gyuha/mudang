## 전역 게임 상태 기계. autoload로 등록(`GameState`). ([docs/11]§2.1, [docs/06]§3)
## 화면 전이는 이 state를 따라 Main이 현재 화면 노드를 교체한다.
## NOTE: autoload명 `GameState`와 class_name 충돌 회피 위해 class_name 미선언. 전역 접근은 autoload명으로.
extends Node

## 화면/흐름 상태 ([docs/11]§2.1)
enum S { BOOT, DASHBOARD, BRIEFING, LOADOUT, RUN, LEVELUP_PAUSE, RESULT }

## 현재 상태가 바뀌면 발신. 인자는 새 상태값(S)
signal state_changed(new_state: S)

var state: S = S.BOOT

## 상태 전이. 같은 값으로의 전이는 무시한다.
func set_state(new_state: S) -> void:
	if new_state == state:
		return
	state = new_state
	state_changed.emit(new_state)

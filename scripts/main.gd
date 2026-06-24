## 진입점. GameState.state에 따라 현재 화면 노드를 교체한다. ([docs/06]§3, [docs/11]§2.1, [docs/10] 메타 루프)
## BOOT → DASHBOARD 진입 → (스테이지 선택) LOADOUT → (편성) RUN → (승패) RESULT → (복귀) DASHBOARD.
class_name Main
extends Node

## 현재 떠 있는 화면 노드(상태 전이 시 교체 대상).
var _screen: Node

func _ready() -> void:
	GameState.state_changed.connect(_on_state_changed)
	GameState.set_state(GameState.S.DASHBOARD)

## 상태 전이 시 화면 노드 교체. LEVELUP_PAUSE는 RUN 위 오버레이(RunScene 내부 처리) — 교체 안 함.
func _on_state_changed(new_state: int) -> void:
	var next: Node = null
	match new_state:
		GameState.S.DASHBOARD: next = Dashboard.new()
		GameState.S.LOADOUT: next = Loadout.new()
		GameState.S.RUN: next = RunScene.new()
		GameState.S.RESULT: next = Result.new()
		_: return   # BOOT/BRIEFING/LEVELUP_PAUSE — 화면 교체 없음
	if _screen != null:
		_screen.queue_free()
	_screen = next
	add_child(next)

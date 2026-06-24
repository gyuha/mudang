## 결과 화면 — 런 승/패 표시(메타 셸 ②). ([docs/10] 결과, [docs/11]§2.1)
## GameState.last_result(RunScene가 RESULT 전이 시 기록)를 읽어 표시. 승리 메타 저장은 RunScene가 이미 1회 수행 — 여기선 중복 저장 안 함.
## "대시보드로" → DASHBOARD 전이. 표시/클릭 체감은 GUI(사용자).
class_name Result
extends Control

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build()

## 결과 라벨 텍스트(win/lose/none).
func result_text() -> String:
	match GameState.last_result:
		&"win": return "밤을 넘겼다 — 승리"
		&"lose": return "쓰러졌다 — 패배"
		_: return "—"

## 대시보드 복귀. (메타 저장은 RunScene가 승리 시 이미 완료 — 여기선 전이만)
func to_dashboard() -> void:
	GameState.set_state(GameState.S.DASHBOARD)

func _build() -> void:
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	add_child(panel)
	var box := VBoxContainer.new()
	panel.add_child(box)
	var label := Label.new()
	label.text = result_text()
	box.add_child(label)
	var btn := Button.new()
	btn.text = "대시보드로"
	btn.pressed.connect(to_dashboard)
	box.add_child(btn)

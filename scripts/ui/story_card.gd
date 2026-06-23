## 서사 카드(D23, docs/11 §5) — 장 시작 미니멀 텍스트 카드(일러스트 + 텍스트).
## StageDef 데이터로 표시, 클릭/입력 시 닫고 런 시작. 일시정지 동안 입력 받음.
## build_text/이미지 로드는 헤드리스 검증, 렌더/딕미스 체감은 GUI.
class_name StoryCard
extends CanvasLayer

var _shown: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

## 일러스트 경로 + 텍스트로 카드 표시(텍스트 비면 미표시, false 반환). 게임 일시정지.
func show_card(image_path: String, text: String) -> bool:
	if text.strip_edges() == "" or _shown:
		return false
	_shown = true
	get_tree().paused = true
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	# 배경 암전.
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.7)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(dim)
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_CENTER)
	root.add_child(box)
	# 일러스트(있으면).
	var tex: Texture2D = null
	if image_path != "":
		tex = load(image_path) as Texture2D
	if tex != null:
		var img := TextureRect.new()
		img.texture = tex
		img.custom_minimum_size = Vector2(640, 360)
		img.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		box.add_child(img)
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(640, 0)
	box.add_child(label)
	var btn := Button.new()
	btn.text = "밤으로 ▶"
	btn.pressed.connect(_dismiss)
	box.add_child(btn)
	return true

func _dismiss() -> void:
	for ch in get_children():
		ch.queue_free()
	get_tree().paused = false
	_shown = false

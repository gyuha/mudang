## 서사 카드 검증. StageDef intro 필드 + StoryCard.show_card(텍스트 유무 분기, 라벨에 텍스트).
## 렌더/딕미스 체감은 GUI.
extends Node2D
func _ready() -> void:
	var st := load("res://data/stages/stage_hwalinseo.tres") as StageDef
	var data_ok := st.intro_text.strip_edges() != "" and st.intro_image_path != ""
	var c := StoryCard.new(); add_child(c)
	var empty_no := c.show_card("", "") == false       # 빈 텍스트 → 미표시
	var shown := c.show_card(st.intro_image_path, st.intro_text) == true
	var has_text := _find_label(c, st.intro_text)
	print("META data_ok=%s empty_no=%s shown=%s has_text=%s" % [data_ok, empty_no, shown, has_text])
	print("STORY VERDICT => %s" % ["PASS" if (data_ok and empty_no and shown and has_text) else "FAIL"])
	get_tree().quit()
func _find_label(n: Node, text: String) -> bool:
	for ch in n.get_children():
		if ch is Label and ch.text == text:
			return true
		if _find_label(ch, text):
			return true
	return false

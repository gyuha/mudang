## 대시보드 — 스테이지 선택 화면(메타 셸 ①). ([docs/10], [docs/11]§2.1, D21)
## MetaProgress를 읽어 6스테이지를 장 순서로 보여주고, unlock_requires 해금 게이트를 적용한다.
## 해금 스테이지 선택 → GameState.selected_stage_path 설정 + LOADOUT 전이. (편성/결과는 별 화면)
## 선택/해금 판정은 헤드리스 검증 가능. 레이아웃·클릭 체감은 GUI(사용자).
class_name Dashboard
extends Control

## 장 순서 스테이지 경로(해금 사슬은 unlock_requires가, 표시 순서는 이 배열이 정함).
const STAGE_PATHS: Array[String] = [
	"res://data/stages/stage_hwalinseo.tres",
	"res://data/stages/stage_musnyeo_village.tres",
	"res://data/stages/stage_mountain_pass.tres",
	"res://data/stages/stage_yangban_gut.tres",
	"res://data/stages/stage_seonsucheong.tres",
	"res://data/stages/stage_palace_wraith.tres",
]

var meta: MetaProgress
var _box: VBoxContainer

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	if meta == null:
		meta = MetaProgress.load_or_new()
	_build()

## 스테이지 항목 목록 {path,id,display_name,unlocked}. (헤드리스 검증/빌드 공용)
func stage_entries() -> Array:
	var out: Array = []
	for p in STAGE_PATHS:
		var s := load(p) as StageDef
		if s == null:
			continue
		out.append({
			"path": p,
			"id": String(s.id),
			"display_name": s.display_name,
			"unlocked": _is_unlocked(s),
		})
	return out

## 해금 판정: unlock_requires가 비었거나(1장), 선행 스테이지가 전부 클리어 해금됨.
func _is_unlocked(s: StageDef) -> bool:
	if s.unlock_requires.is_empty():
		return true
	for req in s.unlock_requires:
		if String(req) not in meta.unlocked_stages:
			return false
	return true

## 스테이지 선택. 잠겨 있으면 무시(false). 해금이면 selected_stage_path 설정 + LOADOUT 전이(true).
func select_stage(path: String) -> bool:
	var s := load(path) as StageDef
	if s == null or not _is_unlocked(s):
		return false
	GameState.selected_stage_path = path
	GameState.set_state(GameState.S.LOADOUT)
	return true

func _build() -> void:
	# 배경(타이틀 키 비주얼). 없으면 생략.
	var bg_tex := load("res://assets/bg/title_bg.png") as Texture2D
	if bg_tex != null:
		var bg := TextureRect.new()
		bg.texture = bg_tex
		bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		bg.set_anchors_preset(Control.PRESET_FULL_RECT)
		bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(bg)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	add_child(panel)
	_box = VBoxContainer.new()
	panel.add_child(_box)

	var title := Label.new()
	title.text = "무녀: 밤을 부르는 자 — 스테이지 선택"
	_box.add_child(title)

	for e in stage_entries():
		var b := Button.new()
		var lock := "" if e.unlocked else "  🔒"
		b.text = "%s%s" % [e.display_name if e.display_name != "" else e.id, lock]
		b.disabled = not e.unlocked
		b.pressed.connect(select_stage.bind(e.path))
		_box.add_child(b)

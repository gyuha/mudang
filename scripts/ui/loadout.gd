## 편성(로드아웃) — 출전 동료 선택 화면(메타 셸 ②). ([docs/10] 편성, [docs/03]§5 loadout_slots, D16)
## 해금 동료 풀에서 loadout_slots만큼 선택 → GameState.selected_companions 설정 + RUN 전이.
## 선택/슬롯 로직은 헤드리스 검증 가능. 레이아웃·클릭 체감은 GUI(사용자).
class_name Loadout
extends Control

## 슬라이스 기본 출전 풀 3종(항상 선택 가능). 추가 동료는 meta.unlocked_companions로 확장. ([docs/12])
const BASE_COMPANIONS: Array[String] = [
	"res://data/companions/hwarang.tres",
	"res://data/companions/hwaljabi.tres",
	"res://data/companions/gyeonseup.tres",
]

var meta: MetaProgress
## 선택된 동료 경로(최대 meta.loadout_slots).
var selected: Array[String] = []
var _box: VBoxContainer

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	if meta == null:
		meta = MetaProgress.load_or_new()
	_build()

## 출전 가능 동료 목록 {path,id,display_name,role}. 기본 풀 + 해금 추가분(.tres 존재분만).
func available_companions() -> Array:
	var paths: Array[String] = BASE_COMPANIONS.duplicate()
	for cid in meta.unlocked_companions:
		var p := "res://data/companions/%s.tres" % String(cid)
		if p not in paths and ResourceLoader.exists(p):
			paths.append(p)
	var out: Array = []
	for p in paths:
		var c := load(p) as CompanionDef
		if c == null:
			continue
		out.append({"path": p, "id": String(c.id), "display_name": c.display_name, "role": String(c.role_id)})
	return out

## 동료 토글. 이미 선택돼 있으면 해제, 아니면 슬롯 여유가 있을 때만 추가. 변경 여부 반환.
func toggle_companion(path: String) -> bool:
	if path in selected:
		selected.erase(path)
		_refresh()
		return true
	if selected.size() >= meta.loadout_slots:
		return false   # 슬롯 가득
	selected.append(path)
	_refresh()
	return true

## 출전 확정. 1명 이상 선택돼 있어야 함. 성공 시 GameState에 편성 기록 + RUN 전이.
func confirm() -> bool:
	if selected.is_empty():
		return false
	GameState.selected_companions = selected.duplicate()
	GameState.set_state(GameState.S.RUN)
	return true

func _build() -> void:
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	add_child(panel)
	_box = VBoxContainer.new()
	panel.add_child(_box)
	_refresh()

## 목록 재구성(선택 표시 갱신). 동료 토글 버튼 + 출전 버튼.
func _refresh() -> void:
	for ch in _box.get_children():
		ch.queue_free()
	var title := Label.new()
	title.text = "출전 편성 (슬롯 %d / 선택 %d)" % [meta.loadout_slots, selected.size()]
	_box.add_child(title)
	for e in available_companions():
		var b := Button.new()
		var mark := "■ " if e.path in selected else "□ "
		b.text = "%s%s  [%s]" % [mark, e.display_name if e.display_name != "" else e.id, e.role]
		b.pressed.connect(toggle_companion.bind(e.path))
		_box.add_child(b)
	var go := Button.new()
	go.text = "출전"
	go.disabled = selected.is_empty()
	go.pressed.connect(confirm)
	_box.add_child(go)

## 무녀 레벨업 3택 일시정지 UI(M5-UI). ([docs/01]§6, [docs/03]§2, D11·D12)
## 무녀 pending_picks>0이면 게임 일시정지 + 미만렙 카드 3택 표시 → 클릭 시 적용·pending 소비.
## pick_candidates/적용 로직은 헤드리스 검증 가능. 일시정지·렌더·클릭 체감은 GUI(사용자).
class_name LevelUpChoice
extends CanvasLayer

const CHOICES: int = 3

var pool: Array = []            # Array[MudangUpgrade]
var levels: Dictionary = {}     # {id: 현재 레벨}
var mudang: Mudang
var _showing: bool = false
var _box: VBoxContainer

func _ready() -> void:
	# 일시정지 중에도 입력 처리.
	process_mode = Node.PROCESS_MODE_ALWAYS

func setup(p: Array, lv: Dictionary, m: Mudang) -> void:
	pool = p
	levels = lv
	mudang = m

## 적용 가능(미만렙) 카드 중 최대 CHOICES개. (슬라이스: 결정 단순 — 앞에서부터; 가중 추첨은 후속)
func pick_candidates() -> Array:
	var out: Array = []
	for up in pool:
		if int(levels.get(up.id, 0)) < up.max_level:
			out.append(up)
		if out.size() >= CHOICES:
			break
	return out

## 매 프레임 RunScene가 호출. pending 있고 표시 중 아니면 3택 띄움.
func maybe_show() -> void:
	if _showing or mudang == null or mudang.pending_picks() == 0:
		return
	var cands := pick_candidates()
	if cands.is_empty():
		return   # 전부 만렙 — 표시할 카드 없음(무한 방지)
	_show(cands)

func _show(cands: Array) -> void:
	_showing = true
	get_tree().paused = true
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	add_child(panel)
	_box = VBoxContainer.new()
	panel.add_child(_box)
	var title := Label.new()
	title.text = "레벨 업! 주술을 고르시오 (Lv %d)" % mudang.mudang_level
	_box.add_child(title)
	for up in cands:
		var b := Button.new()
		b.text = "%s  [%s]  Lv %d→%d" % [
			up.display_name, up.category, int(levels.get(up.id, 0)), int(levels.get(up.id, 0)) + 1]
		b.pressed.connect(_on_pick.bind(up))
		_box.add_child(b)

## 카드 선택: 적용 + 레벨/ pending 갱신 + 닫기(다음 pending 있으면 다음 프레임 maybe_show가 재표시).
func _on_pick(up: MudangUpgrade) -> void:
	mudang.apply_upgrade(up)
	levels[up.id] = int(levels.get(up.id, 0)) + 1
	_close()

func _close() -> void:
	if _box != null and _box.get_parent() != null:
		_box.get_parent().queue_free()   # 패널 통째 제거
	_box = null
	_showing = false
	get_tree().paused = false

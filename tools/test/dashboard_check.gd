## 대시보드 검증(task 21). 6스테이지 노출 + 해금 게이트 + 선택→LOADOUT 전이.
extends Node2D

func _ready() -> void:
	GameState.set_state(GameState.S.DASHBOARD)

	# 신규 메타(저장 없음 → unlocked_stages 비어 1장만 해금).
	var d := Dashboard.new()
	d.meta = MetaProgress.new()
	add_child(d)

	var entries := d.stage_entries()
	var count_ok: bool = entries.size() == 6
	var s1_unlocked: bool = entries[0].unlocked and entries[0].id == "stage_hwalinseo"
	var s2_locked: bool = not entries[1].unlocked  # musnyeo_village requires hwalinseo
	print("  entries=%d s1_unlocked=%s s2_locked=%s" % [entries.size(), s1_unlocked, s2_locked])

	# 잠긴 스테이지 선택 → false, 전이 없음.
	var locked_path: String = entries[1].path
	var lock_rejected: bool = d.select_stage(locked_path) == false and GameState.state == GameState.S.DASHBOARD
	print("  locked select rejected=%s state=%d" % [lock_rejected, GameState.state])

	# 해금 스테이지(1장) 선택 → true, selected_stage_path 설정 + LOADOUT 전이.
	var s1_path: String = entries[0].path
	var ok_select: bool = d.select_stage(s1_path)
	var routed: bool = ok_select and GameState.selected_stage_path == s1_path and GameState.state == GameState.S.LOADOUT
	print("  unlocked select=%s path_ok=%s state=%d(LOADOUT=%d)" % [ok_select, GameState.selected_stage_path == s1_path, GameState.state, GameState.S.LOADOUT])

	var pass_all: bool = count_ok and s1_unlocked and s2_locked and lock_rejected and routed
	print("DASHBOARD VERDICT => %s" % ["PASS" if pass_all else "FAIL"])
	get_tree().quit()

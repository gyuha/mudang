## M7 영구메타 검증(S1~S2). 기본값·클리어 정산/해금·save→load 영속·migration을 판정.
## 편성 UI는 M7-UI(human wall) — 여기선 저장/해금/정산 로직만. user://save.json 격리(시작/끝 삭제).
extends Node2D

func _ready() -> void:
	_clear_save()
	var results := {}
	results["defaults"] = _check_defaults()
	results["record_clear"] = _check_record_clear()
	results["persist"] = _check_persist()
	results["migration"] = _check_migration()
	_clear_save()

	var all := true
	for k in results:
		print("META %s => %s" % [k, "PASS" if results[k] else "FAIL"])
		all = all and results[k]
	print("META VERDICT => %s" % ["PASS" if all else "FAIL"])
	get_tree().quit()

func _clear_save() -> void:
	if FileAccess.file_exists(MetaProgress.SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(MetaProgress.SAVE_PATH))
		# user:// 절대 경로 삭제 폴백
		var d := DirAccess.open("user://")
		if d != null and d.file_exists("save.json"):
			d.remove("save.json")

func _stage() -> StageDef:
	return load("res://data/stages/stage_hwalinseo.tres") as StageDef

# S1: 신규 기본값.
func _check_defaults() -> bool:
	var m := MetaProgress.load_or_new()   # 파일 없음 → 기본값
	print("  defaults ver=%d slots=%d cur=%d stages=%d" % [
		m.version, m.loadout_slots, m.meta_currency, m.unlocked_stages.size()])
	return m.version == 1 and m.loadout_slots == 2 and m.meta_currency == 0 \
		and m.unlocked_stages.is_empty()

# S2: 클리어 정산(첫 보너스 1회) + 해금.
func _check_record_clear() -> bool:
	var m := MetaProgress.new()
	var st := _stage()   # reward: meta_currency 50 + first_clear_bonus 100
	m.record_clear(st, 360.0)
	var after_first := m.meta_currency        # 150
	var cleared := bool(m.stage_records[String(st.id)]["cleared"])
	var unlocked := String(st.id) in m.unlocked_stages
	m.record_clear(st, 360.0)
	var after_second := m.meta_currency        # +50 (보너스 없음) = 200
	print("  record_clear first=%d second=%d cleared=%s unlocked=%s" % [
		after_first, after_second, cleared, unlocked])
	return after_first == 150 and after_second == 200 and cleared and unlocked

# S1: save → load 왕복 영속.
func _check_persist() -> bool:
	_clear_save()
	var m := MetaProgress.new()
	m.meta_currency = 275
	m.unlocked_stages = ["stage_hwalinseo"]
	m.stage_records = {"stage_hwalinseo": {"cleared": true, "best_time": 360.0}}
	m.save()
	var l := MetaProgress.load_or_new()
	print("  persist cur=%d stages=%d cleared=%s" % [
		l.meta_currency, l.unlocked_stages.size(),
		l.stage_records.get("stage_hwalinseo", {}).get("cleared", false)])
	return l.meta_currency == 275 and l.unlocked_stages.size() == 1 \
		and bool(l.stage_records["stage_hwalinseo"]["cleared"])

# S1: 구버전/누락 파일 → migration 안전(크래시 없이 기본값 보정).
func _check_migration() -> bool:
	_clear_save()
	var f := FileAccess.open(MetaProgress.SAVE_PATH, FileAccess.WRITE)
	f.store_string('{"version":0,"meta_currency":42}')   # v0, 대부분 필드 누락
	f.close()
	var l := MetaProgress.load_or_new()
	print("  migration ver=%d cur=%d slots=%d (누락 필드 기본값)" % [
		l.version, l.meta_currency, l.loadout_slots])
	return l.version == 1 and l.meta_currency == 42 and l.loadout_slots == 2

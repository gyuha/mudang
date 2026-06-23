## 영구메타(M7) — 런을 넘어 저장되는 진행. ([docs/03]§5, [docs/11]§3, D15·D16)
## user://save.json (version + migration). 가볍게 유지(메타가 세지면 난이도 설계 종속 — D15).
## 편성 화면 UI는 M7-UI Non-goal — 이 클래스는 저장/해금/정산 데이터 로직만.
class_name MetaProgress
extends RefCounted

const CURRENT_VERSION: int = 1
const SAVE_PATH: String = "user://save.json"

var version: int = CURRENT_VERSION
## 클리어로 해금된 스테이지 id 집합.
var unlocked_stages: Array = []
## 해금 동료 id 집합.
var unlocked_companions: Array = []
## 출전 슬롯 수(시작 2 → 메타 최대 4, D16).
var loadout_slots: int = 2
## 메타 재화(원혼 정수).
var meta_currency: int = 0
## 소폭 영구 강화 {id: level} — 구조만 영속, 효과 적용은 후속(런 주입). ([docs/11]§3.2)
var meta_upgrades: Dictionary = {}
## 스테이지 기록 {id: {cleared: bool, best_time: float}}.
var stage_records: Dictionary = {}
var tutorial_done: bool = false

## 세이브 로드(없거나 손상 시 기본값, 구버전이면 마이그레이션). ([docs/11]§3.1)
static func load_or_new() -> MetaProgress:
	var m := MetaProgress.new()
	if not FileAccess.file_exists(SAVE_PATH):
		return m
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return m
	var txt := f.get_as_text()
	f.close()
	var data: Variant = JSON.parse_string(txt)
	if typeof(data) != TYPE_DICTIONARY:
		return m   # 손상 파일 → 기본값(안전)
	if int(data.get("version", 0)) < CURRENT_VERSION:
		data = _migrate(data)
	m._from_dict(data)
	return m

func save() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(_to_dict()))
	f.close()

## 클리어 정산·해금. 첫 클리어면 first_clear_bonus 1회 + 매 클리어 meta_currency 적립. ([docs/03]§5)
func record_clear(stage: StageDef, clear_time: float) -> void:
	var id := String(stage.id)
	var rec: Dictionary = stage_records.get(id, {"cleared": false, "best_time": 0.0})
	var first := not bool(rec.get("cleared", false))
	rec["cleared"] = true
	var bt := float(rec.get("best_time", 0.0))
	rec["best_time"] = max(bt, clear_time)   # 생존 시간(길수록 좋음)
	stage_records[id] = rec
	if stage.reward != null:
		meta_currency += stage.reward.meta_currency
		if first:
			meta_currency += stage.reward.first_clear_bonus
	if id not in unlocked_stages:
		unlocked_stages.append(id)
	var cid := String(stage.unlock_companion)
	if cid != "" and cid not in unlocked_companions:
		unlocked_companions.append(cid)

## 스키마 진화 훅. 구버전/누락 필드 → 현재 버전 기본값으로 보정. ([docs/11]§3.1)
static func _migrate(data: Dictionary) -> Dictionary:
	# v0/누락 → v1: version만 올리고 누락 필드는 _from_dict의 get 기본값이 처리.
	data["version"] = CURRENT_VERSION
	return data

func _to_dict() -> Dictionary:
	return {
		"version": version,
		"unlocked_stages": unlocked_stages,
		"unlocked_companions": unlocked_companions,
		"loadout_slots": loadout_slots,
		"meta_currency": meta_currency,
		"meta_upgrades": meta_upgrades,
		"stage_records": stage_records,
		"tutorial_done": tutorial_done,
	}

func _from_dict(data: Dictionary) -> void:
	version = int(data.get("version", CURRENT_VERSION))
	unlocked_stages = data.get("unlocked_stages", [])
	unlocked_companions = data.get("unlocked_companions", [])
	loadout_slots = int(data.get("loadout_slots", 2))
	meta_currency = int(data.get("meta_currency", 0))
	meta_upgrades = data.get("meta_upgrades", {})
	stage_records = data.get("stage_records", {})
	tutorial_done = bool(data.get("tutorial_done", false))

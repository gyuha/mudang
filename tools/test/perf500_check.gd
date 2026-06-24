## C4 성능(M-S 스케일업). 헤드리스는 GPU 드로우 fps를 못 재므로 두 가지를 검증한다:
## (1) 500마리 시뮬 로직(tick)이 프레임 예산(16.6ms) 내 — 500@60fps의 CPU측 전제.
## (2) 렌더 백엔드가 노드 500개가 아니라 텍스처별 MultiMesh 배치 — 500@60fps의 아키텍처 전제.
extends Node2D

const TARGET: int = 500
const BUDGET_MS: float = 16.6
const FRAMES: int = 60

func _ready() -> void:
	var es := EnemySystem.new()
	add_child(es)
	var tgt := Node2D.new()
	tgt.global_position = Vector2(0, 0)
	add_child(tgt)
	es.ally_targets = [tgt]

	# 여러 적종 분산 스폰(텍스처 버킷 다양성 반영).
	var defs: Array[EnemyDef] = []
	for f in ["mob_low", "changgwi", "dokkaebi", "ghost_maiden", "plague", "mask_spirit"]:
		var d := load("res://data/enemies/%s.tres" % f) as EnemyDef
		if d != null: defs.append(d)
	var ang := 0.0
	for i in TARGET:
		var d: EnemyDef = defs[i % defs.size()]
		ang += 2.39996  # 황금각 분산
		es.spawn(d, Vector2(cos(ang), sin(ang)) * (50.0 + i))
	var active := es.active_count()

	# 워밍업 1틱 후 60틱 평균 측정.
	es.tick(0.016)
	var t0 := Time.get_ticks_usec()
	for _f in FRAMES:
		es.tick(0.016)
	var avg_ms := float(Time.get_ticks_usec() - t0) / FRAMES / 1000.0

	# 배치 렌더 검증: Sprite2D 슬롯 노드 0개, 텍스처별 MultiMeshInstance2D만.
	var mmi := 0
	var spr := 0
	for ch in es.get_children():
		if ch is MultiMeshInstance2D: mmi += 1
		if ch is Sprite2D: spr += 1

	var active_ok: bool = active >= TARGET
	var budget_ok: bool = avg_ms < BUDGET_MS
	var batched_ok: bool = spr == 0 and mmi > 0 and mmi <= 20
	var pass_all: bool = active_ok and budget_ok and batched_ok
	print("  active=%d/%d (%s)" % [active, TARGET, active_ok])
	print("  avg tick=%.3f ms / budget %.1f (%s)" % [avg_ms, BUDGET_MS, budget_ok])
	print("  render: MultiMeshInstance2D=%d Sprite2D=%d batched=%s" % [mmi, spr, batched_ok])
	print("PERF500 VERDICT => %s" % ["PASS" if pass_all else "FAIL"])
	get_tree().quit()

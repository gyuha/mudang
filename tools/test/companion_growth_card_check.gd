## 동료 성장 카드 검증(C5). 레벨업 pending → 카드 적용 → 인스턴스 스탯 상승, 공유 def 비변형, 역할 필터.
extends Node2D

func _ready() -> void:
	var path := "res://data/companions/hwarang.tres"   # tank, attack_damage=8
	var base_atk: float = (load(path) as CompanionDef).attack_damage

	var c := Companion.new()
	c.def = load(path)
	add_child(c)   # _ready에서 def = def.duplicate()

	# 혼불 EXP로 레벨업 → pending 확보.
	c.add_companion_exp(100.0)
	var pend_before := c.pending_upgrades
	var had_pending: bool = pend_before > 0

	# attack_damage +3 카드(any) 적용.
	var power := load("res://data/upgrades/companion/comp_power.tres") as CompanionUpgrade
	var atk_before: float = c.def.attack_damage
	c.apply_companion_upgrade(power)
	var atk_after: float = c.def.attack_damage
	var grew: bool = atk_after > atk_before
	var pend_spent: bool = c.pending_upgrades == pend_before - 1

	# 공유 리소스 비변형: 새로 로드한 def는 원본 값.
	var fresh_atk: float = (load(path) as CompanionDef).attack_damage
	var shared_clean: bool = is_equal_approx(fresh_atk, base_atk)

	# 역할 필터: 치유강화(healer 전용)는 탱(hwarang)에 적용 불가.
	var mending := load("res://data/upgrades/companion/comp_mending.tres") as CompanionUpgrade
	var role_gate: bool = mending.applies_to(&"healer") and not mending.applies_to(&"tank") and not c.can_take_upgrade(mending)

	print("  pending: before=%d after=%d spent=%s" % [pend_before, c.pending_upgrades, pend_spent])
	print("  attack_damage: %.1f→%.1f grew=%s" % [atk_before, atk_after, grew])
	print("  shared def clean: base=%.1f fresh=%.1f %s" % [base_atk, fresh_atk, shared_clean])
	print("  role filter(healer카드 tank적용불가)=%s" % role_gate)

	var pass_all: bool = had_pending and grew and pend_spent and shared_clean and role_gate
	print("COMPANION_GROWTH VERDICT => %s" % ["PASS" if pass_all else "FAIL"])
	get_tree().quit()

## 목표/승패 판정(M6) — 순수 함수. ([docs/04]§3, [docs/01]§7, [docs/09]§3, D14)
## 패배: 무녀 사망 또는 거점 파괴(주 패배 조건, D6-a). 승리: survive duration 도달.
## 슬라이스 목표 = survive_time + defend_target. 그 외(kill_boss/purify_zone)는 후속.
class_name ObjectiveEval
extends RefCounted

const NONE: StringName = &"none"
const WIN: StringName = &"win"
const LOSE: StringName = &"lose"

## 현재 런 상태로 결과 판정. 패배 우선(무녀/거점), 그다음 생존 승리, 아니면 none.
static func evaluate(run_time: float, duration: float, mudang_hp: float, stronghold_hp: float) -> StringName:
	if mudang_hp <= 0.0:
		return LOSE
	if stronghold_hp <= 0.0:
		return LOSE
	if run_time >= duration:
		return WIN
	return NONE

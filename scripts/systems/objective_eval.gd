## 목표/승패 판정(M6) — 순수 함수. ([docs/04]§3, [docs/01]§7, [docs/09]§3, D14)
## 패배: 무녀 사망 또는 거점 파괴(주 패배 조건, D6-a). 승리: kill_boss 완료 / purify_zone 완료 / survive duration 도달.
## 슬라이스 목표 = survive_time + defend_target. kill_boss는 3장~, purify_zone은 4·5장~ 지원.
class_name ObjectiveEval
extends RefCounted

const NONE: StringName = &"none"
const WIN: StringName = &"win"
const LOSE: StringName = &"lose"

## 현재 런 상태로 결과 판정. 패배 우선(무녀/거점), 그다음 목표별 승리(kill_boss/purify_zone), 아니면 duration.
## kill_boss/purify_zone 스테이지는 해당 목표 완료만이 승리 — duration은 그 경우 승리 트리거 아님.
static func evaluate(run_time: float, duration: float, mudang_hp: float, stronghold_hp: float,
		has_kill_boss: bool = false, kill_boss_done: bool = false,
		has_purify: bool = false, purify_done: bool = false) -> StringName:
	if mudang_hp <= 0.0:
		return LOSE
	if stronghold_hp <= 0.0:
		return LOSE
	if has_kill_boss:
		return WIN if kill_boss_done else NONE
	if has_purify:
		return WIN if purify_done else NONE
	if run_time >= duration:
		return WIN
	return NONE

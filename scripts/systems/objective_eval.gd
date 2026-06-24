## 목표/승패 판정(M6) — 순수 함수. ([docs/04]§3, [docs/01]§7, [docs/09]§3, D14)
## 패배: 무녀 사망 또는 거점 파괴(주 패배 조건, D6-a). 승리: survive duration 도달 또는 kill_boss 완료.
## 슬라이스 목표 = survive_time + defend_target. kill_boss는 3장부터 지원. purify_zone은 후속(예약).
class_name ObjectiveEval
extends RefCounted

const NONE: StringName = &"none"
const WIN: StringName = &"win"
const LOSE: StringName = &"lose"

## 현재 런 상태로 결과 판정. 패배 우선(무녀/거점), 그다음 승리, 아니면 none.
## kill_boss 스테이지(has_kill_boss=true)는 대상 보스 처치(kill_boss_done)만이 승리 — duration은 승리 트리거 아님.
static func evaluate(run_time: float, duration: float, mudang_hp: float, stronghold_hp: float,
		has_kill_boss: bool = false, kill_boss_done: bool = false) -> StringName:
	if mudang_hp <= 0.0:
		return LOSE
	if stronghold_hp <= 0.0:
		return LOSE
	if has_kill_boss:
		return WIN if kill_boss_done else NONE
	if run_time >= duration:
		return WIN
	return NONE

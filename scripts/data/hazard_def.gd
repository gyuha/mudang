## 정적 해저드존(D22 계층①, [docs/10]§6). 사각 구역 + 초당 피해. 확산 시뮬은 v1 컷 — 정적 존으로 대체.
## 데이터 주도: StageDef.hazards에 인스턴스로 담는다. 구역 내 유닛(무녀/동료)은 dps×dt 피해.
class_name HazardDef
extends Resource

## 구역 중심(월드).
@export var pos: Vector2 = Vector2.ZERO
## 구역 크기(사각 폭/높이).
@export var size: Vector2 = Vector2(120, 120)
## 초당 피해.
@export var dps: float = 8.0
## 종류: fire | poison | curse (연출/정화 대상 구분용 — 슬라이스는 피해만).
@export var hazard_type: StringName = &"fire"

## 월드 좌표가 구역 안인가.
func contains(p: Vector2) -> bool:
	return Rect2(pos - size * 0.5, size).has_point(p)

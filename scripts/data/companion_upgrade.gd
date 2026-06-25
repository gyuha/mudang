## 동료 성장 카드 1종(M5) — 데이터 주도 동료 강화. ([docs/03]§3, [docs/09]§4, D11)
## MudangUpgrade와 동일 구조. 효과는 동료의 인스턴스 def 복사본 속성에 레벨당 델타 가산
## (Companion._ready가 def.duplicate()로 복사 — 공유 CompanionDef 리소스는 변형되지 않는다).
class_name CompanionUpgrade
extends Resource

## 식별자 (파일명과 일치 권장)
@export var id: StringName = &""
@export var display_name: String = ""
## 적용 역할 필터: any | tank | ranged | healer
@export var role_filter: StringName = &"any"
@export var max_level: int = 5
## 강화 대상 CompanionDef 속성명들(병렬 배열, deltas와 1:1). 레벨당 가산.
@export var targets: Array[StringName] = []
@export var deltas: Array[float] = []

## 이 카드가 해당 역할 동료에 적용 가능한가.
func applies_to(role: StringName) -> bool:
	return role_filter == &"any" or role_filter == role

## 1레벨 적용: 각 target 속성에 delta 가산. c.def는 인스턴스 복사본(공유 아님).
func apply_to(c: Object) -> void:
	for i in targets.size():
		c.def.set(targets[i], c.def.get(targets[i]) + deltas[i])

## 무녀 업그레이드 1종(M5) — 데이터 주도 레버 강화 카드. ([docs/01]§6, [docs/09]§4, D7·D11)
## 공격 주술 없음(D7) — 전부 컨트롤/서포트/케어. 효과는 Mudang @export 파라미터에 레벨당 델타 가산.
class_name MudangUpgrade
extends Resource

## 식별자 (파일명과 일치 권장)
@export var id: StringName = &""
@export var display_name: String = ""
## 계열: survival|aura|knockback|soulfire|rally|care|util ([docs/01]§6)
@export var category: StringName = &"aura"
@export var max_level: int = 5
## 강화 대상 Mudang 속성명들(병렬 배열, deltas와 1:1). 레벨당 가산.
@export var targets: Array[StringName] = []
@export var deltas: Array[float] = []

## 1레벨 적용: 각 target 속성에 delta 가산. (Mudang @export 레버 파라미터)
func apply_to(mudang: Object) -> void:
	for i in targets.size():
		mudang.set(targets[i], mudang.get(targets[i]) + deltas[i])

## 적 처치 시 혼불 드랍 정의. ([docs/03], [docs/04])
## 혼불 2종: 무녀 혼불(즉시 흡수) / 동료 혼불(보유→근접 자동 전달).
class_name DropTable
extends Resource

## 무녀 혼불 드랍 확률 (0~1)
@export_range(0.0, 1.0) var mudang_soulfire_chance: float = 0.0
## 드랍 시 무녀 혼불 개수
@export var mudang_soulfire_amount: int = 0
## 동료 혼불 드랍 확률 (0~1)
@export_range(0.0, 1.0) var companion_soulfire_chance: float = 0.0
## 드랍 시 동료 혼불 개수
@export var companion_soulfire_amount: int = 0

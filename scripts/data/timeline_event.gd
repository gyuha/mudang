## 타임라인 채널 고정 이벤트. ([docs/04]§2.1)
## 예산과 무관하게 time 도달 시 무조건 발동.
class_name TimelineEvent
extends Resource

enum Kind { SPAWN_GROUP, MINIBOSS, RUSH, OBJECTIVE, MODIFIER }

@export var time: float = 0.0
@export var kind: Kind = Kind.SPAWN_GROUP
## SPAWN_GROUP / MINIBOSS / RUSH 에서 스폰할 적
@export var enemy: EnemyDef
@export var count: int = 1
## 유연 파라미터(OBJECTIVE/MODIFIER 등)
@export var payload: Dictionary = {}

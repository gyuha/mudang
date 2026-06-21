## 목표 모듈. ([docs/04]§3, [docs/10]§6)
## 한 스테이지는 여러 목표를 가질 수 있다(Array).
class_name ObjectiveDef
extends Resource

## survive_time | defend_target | purify_zone | kill_boss
@export var kind: StringName = &"survive_time"
## 타입별 파라미터. 예)
##   survive_time : { "time": 360.0 }
##   defend_target: { "target_hp": 300.0 }  (다중 시 여러 ObjectiveDef)
##   purify_zone  : { "order": 0, "charge_time": 20.0 }
##   kill_boss    : { "enemy_id": "boss_hwalinseo" }
@export var params: Dictionary = {}

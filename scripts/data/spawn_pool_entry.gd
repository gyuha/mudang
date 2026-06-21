## 예산 채널 스폰 풀 항목. ([docs/04]§2)
## (저작 단순화: Curve 대신 weight + 활성 구간. 시간대별 변화는 항목을 여러 개 두어 표현)
class_name SpawnPoolEntry
extends Resource

@export var enemy: EnemyDef
## 추첨 가중치
@export var weight: float = 1.0
## 활성 시작 시각(초)
@export var start_time: float = 0.0
## 활성 종료 시각(초). -1 = 런 끝까지
@export var end_time: float = -1.0

func is_active(t: float) -> bool:
	return t >= start_time and (end_time < 0.0 or t <= end_time)

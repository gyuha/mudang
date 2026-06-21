## 진입점. 메인 씬 루트에 붙는 스크립트. ([docs/06]§3, [docs/11]§2.1)
## M0 범위: BOOT → RUN으로 전이하고 RunScene을 자식으로 로드한다.
## 화면 전이(대시보드/브리핑 등)는 후속. 지금은 곧장 런으로 들어간다.
class_name Main
extends Node

func _ready() -> void:
	GameState.set_state(GameState.S.RUN)
	add_child(RunScene.new())

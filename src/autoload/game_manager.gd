extends Node

## ゲーム全体の状態管理を行うシングルトン

signal state_changed(new_state: GameState)

enum GameState { TITLE, HOME, MAP, BATTLE, SETTINGS }

var current_state: GameState = GameState.TITLE
var is_mobile: bool = false

func _ready() -> void:
	is_mobile = OS.has_feature("mobile")
	if is_mobile:
		Engine.max_fps = 30


func change_state(new_state: GameState) -> void:
	current_state = new_state
	state_changed.emit(new_state)

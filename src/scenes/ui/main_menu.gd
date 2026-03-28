extends Control

## メインメニュー画面

@onready var start_button: Button = %StartButton
@onready var settings_button: Button = %SettingsButton


func _ready() -> void:
	start_button.pressed.connect(_on_start_pressed)
	settings_button.pressed.connect(_on_settings_pressed)


func _on_start_pressed() -> void:
	GameManager.change_state(GameManager.GameState.HOME)
	# TODO: ホーム画面へ遷移


func _on_settings_pressed() -> void:
	GameManager.change_state(GameManager.GameState.SETTINGS)
	# TODO: 設定画面へ遷移

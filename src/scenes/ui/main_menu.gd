extends Control

## メインメニュー画面

@onready var start_button: Button = %StartButton
@onready var settings_button: Button = %SettingsButton


func _ready() -> void:
	start_button.pressed.connect(_on_start_pressed)
	settings_button.pressed.connect(_on_settings_pressed)


func _on_start_pressed() -> void:
	# ペットを生成（セーブデータがあればロード、なければ新規作成）
	var pet := SaveManager.load_pet()
	if not pet:
		pet = PetFactory.create("MyPet", Enums.PetType.RUNNER)
		SaveManager.save_pet(pet)

	# 初回起動時は権限リクエスト画面を表示
	if PermissionScreen.needs_permission_request():
		var perm_screen := preload("res://src/scenes/ui/permission_screen.tscn").instantiate()
		get_tree().root.add_child(perm_screen)
		hide()
		perm_screen.permissions_completed.connect(func() -> void:
			perm_screen.queue_free()
			_open_home(pet)
		)
	else:
		_open_home(pet)


func _open_home(pet: PetData) -> void:
	GameManager.change_state(GameManager.GameState.HOME)
	var home := preload("res://src/scenes/ui/home_screen.tscn").instantiate()
	home.setup(pet)
	get_tree().root.add_child(home)
	queue_free()


func _on_settings_pressed() -> void:
	GameManager.change_state(GameManager.GameState.SETTINGS)
	# TODO: 設定画面へ遷移

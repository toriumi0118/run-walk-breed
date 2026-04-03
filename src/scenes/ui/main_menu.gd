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

	# 初回起動: チュートリアル → 権限リクエスト → ホーム
	if TutorialScreen.needs_tutorial():
		_show_tutorial(pet)
	elif PermissionScreen.needs_permission_request():
		_show_permissions(pet)
	else:
		_open_home(pet)


func _show_tutorial(pet: PetData) -> void:
	var tutorial := preload("res://src/scenes/ui/tutorial_screen.tscn").instantiate()
	get_tree().root.add_child(tutorial)
	hide()
	tutorial.completed.connect(func() -> void:
		tutorial.queue_free()
		if PermissionScreen.needs_permission_request():
			_show_permissions(pet)
		else:
			_open_home(pet)
	)


func _show_permissions(pet: PetData) -> void:
	var perm_screen := preload("res://src/scenes/ui/permission_screen.tscn").instantiate()
	get_tree().root.add_child(perm_screen)
	hide()
	perm_screen.permissions_completed.connect(func() -> void:
		perm_screen.queue_free()
		_open_home(pet)
	)


func _open_home(pet: PetData) -> void:
	Transition.transition(func() -> void:
		GameManager.change_state(GameManager.GameState.HOME)
		var home := preload("res://src/scenes/ui/home_screen.tscn").instantiate()
		home.setup(pet)
		get_tree().root.add_child(home)
		queue_free()
	)


func _on_settings_pressed() -> void:
	GameManager.change_state(GameManager.GameState.SETTINGS)
	# TODO: 設定画面へ遷移

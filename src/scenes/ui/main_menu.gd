extends Control

## メインメニュー画面

@onready var start_button: Button = %StartButton
@onready var settings_button: Button = %SettingsButton


func _ready() -> void:
	start_button.pressed.connect(_on_start_pressed)
	settings_button.pressed.connect(_on_settings_pressed)


func _on_start_pressed() -> void:
	GameManager.change_state(GameManager.GameState.HOME)
	# ペットを生成（セーブデータがあればロード、なければ新規作成）
	var pet := SaveManager.load_pet()
	if not pet:
		pet = PetFactory.create("MyPet", Enums.PetType.RUNNER)
		# ダミーの歩数を適用（ネイティブ連携前のテスト用）
		var nurture := NurtureSystem.new()
		nurture.apply_steps(pet, 3000)
	var home := preload("res://src/scenes/ui/home_screen.tscn").instantiate()
	home.setup(pet)
	get_tree().root.add_child(home)
	queue_free()


func _on_settings_pressed() -> void:
	GameManager.change_state(GameManager.GameState.SETTINGS)
	# TODO: 設定画面へ遷移

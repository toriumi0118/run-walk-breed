extends Control
class_name HomeScreen

## ホーム画面
## ペット状態、歩数サマリ、各画面への遷移

@onready var _pet_display: PetDisplay = %PetDisplay
@onready var _stats_label: Label = %StatsLabel
@onready var _steps_label: Label = %StepsLabel
@onready var _distance_label: Label = %DistanceLabel
@onready var _exp_bar: ProgressBar = %ExpBar
@onready var _exp_label: Label = %ExpLabel
@onready var _skill_button: Button = %SkillButton
@onready var _battle_button: Button = %BattleButton
@onready var _map_button: Button = %MapButton

var pet_data: PetData


func _ready() -> void:
	_skill_button.pressed.connect(_on_skill_pressed)
	_battle_button.pressed.connect(_on_battle_pressed)
	_map_button.pressed.connect(_on_map_pressed)


func setup(data: PetData) -> void:
	pet_data = data
	refresh()


func refresh() -> void:
	if not pet_data or not is_node_ready():
		return

	_pet_display.setup(pet_data)

	_stats_label.text = "HP:%d  ATK:%d  DEF:%d  SPD:%d" % [
		pet_data.get_max_hp(),
		pet_data.get_attack(),
		pet_data.get_defense(),
		pet_data.get_speed(),
	]

	_steps_label.text = "%d steps" % pet_data.total_steps
	_distance_label.text = "%.1f km" % (pet_data.total_distance_m / 1000.0)

	_exp_bar.max_value = pet_data.get_exp_to_next_level()
	_exp_bar.value = pet_data.experience
	_exp_label.text = "EXP: %d / %d" % [pet_data.experience, pet_data.get_exp_to_next_level()]


func _on_skill_pressed() -> void:
	GameManager.change_state(GameManager.GameState.HOME)
	# TODO: スキル編成画面へ遷移
	var skill_screen := preload("res://src/scenes/ui/skill_edit_screen.tscn").instantiate()
	skill_screen.setup(pet_data)
	get_tree().root.add_child(skill_screen)
	hide()
	skill_screen.closed.connect(func() -> void:
		skill_screen.queue_free()
		show()
		refresh()
	)


func _on_battle_pressed() -> void:
	GameManager.change_state(GameManager.GameState.BATTLE)
	# ダミー対戦相手を生成
	var opponent := PetFactory.create("Opponent", _random_opponent_type())
	# 対戦相手のレベルをプレイヤーに合わせる
	var nurture := NurtureSystem.new()
	var dummy_steps := pet_data.total_steps + randi_range(-500, 500)
	nurture.apply_steps(opponent, maxi(100, dummy_steps))

	var battle_screen := preload("res://src/scenes/battle/battle_screen.tscn").instantiate()
	get_tree().root.add_child(battle_screen)
	hide()
	battle_screen.start_battle(pet_data, opponent)
	battle_screen.battle_finished.connect(func(result: Dictionary) -> void:
		battle_screen.queue_free()
		show()
		refresh()
	)


func _on_map_pressed() -> void:
	GameManager.change_state(GameManager.GameState.MAP)
	# TODO: マップ画面へ遷移


func _random_opponent_type() -> Enums.PetType:
	var types := [Enums.PetType.RUNNER, Enums.PetType.WALKER, Enums.PetType.SPRINTER]
	return types[randi() % types.size()]

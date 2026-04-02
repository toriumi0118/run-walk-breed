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
@onready var _native_banner: Label = %NativeBanner
@onready var _skill_button: Button = %SkillButton
@onready var _battle_button: Button = %BattleButton
@onready var _map_button: Button = %MapButton

var pet_data: PetData
var _nurture: NurtureSystem
var _last_known_steps: int = 0
var _last_known_distance: float = 0.0


func _ready() -> void:
	_skill_button.pressed.connect(_on_skill_pressed)
	_battle_button.pressed.connect(_on_battle_pressed)
	_map_button.pressed.connect(_on_map_pressed)

	# ヘルスケアデータの自動反映を接続
	_nurture = NurtureSystem.new()
	DataManager.steps_updated.connect(_on_steps_updated)
	DataManager.distance_updated.connect(_on_distance_updated)

	# ネイティブ連携が利用可能なら初回データ取得を要求
	_request_initial_health_data()


func _exit_tree() -> void:
	if DataManager.steps_updated.is_connected(_on_steps_updated):
		DataManager.steps_updated.disconnect(_on_steps_updated)
	if DataManager.distance_updated.is_connected(_on_distance_updated):
		DataManager.distance_updated.disconnect(_on_distance_updated)


func setup(data: PetData) -> void:
	pet_data = data
	_last_known_steps = data.total_steps
	_last_known_distance = data.total_distance_m
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

	_update_native_banner()


func _on_skill_pressed() -> void:
	GameManager.change_state(GameManager.GameState.HOME)
	# TODO: スキル編成画面へ遷移
	var skill_screen := preload("res://src/scenes/ui/skill_edit_screen.tscn").instantiate()
	skill_screen.setup(pet_data)
	get_tree().root.add_child(skill_screen)
	hide()
	skill_screen.closed.connect(func() -> void:
		SaveManager.save_pet(pet_data)
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
		_apply_battle_rewards(result)
		SaveManager.save_pet(pet_data)
		battle_screen.queue_free()
		show()
		refresh()
	)


func _on_map_pressed() -> void:
	GameManager.change_state(GameManager.GameState.MAP)
	var map_screen := preload("res://src/scenes/map/map_screen.tscn").instantiate()
	get_tree().root.add_child(map_screen)
	hide()
	map_screen.closed.connect(func() -> void:
		map_screen.queue_free()
		GameManager.change_state(GameManager.GameState.HOME)
		show()
		refresh()
	)


## バトル報酬を適用（勝利: 200 EXP、引き分け: 100 EXP、敗北: 50 EXP）
func _apply_battle_rewards(result: Dictionary) -> void:
	var reward_exp: int
	match result["result"] as Enums.BattleResult:
		Enums.BattleResult.WIN:
			reward_exp = 200
		Enums.BattleResult.DRAW, Enums.BattleResult.TIMEOUT:
			reward_exp = 100
		_:
			reward_exp = 50

	var old_level := pet_data.level
	pet_data.add_experience(reward_exp)

	# レベルアップ時のスキル習得チェック
	for lv in range(old_level + 1, pet_data.level + 1):
		var new_skills := SkillDatabase.get_learnable_skills(pet_data.pet_type, lv)
		for skill in new_skills:
			pet_data.learn_skill(skill)


## ヘルスケアデータ受信: 歩数の差分をペットに反映
func _on_steps_updated(steps: int) -> void:
	if not pet_data:
		return
	var new_steps := steps - _last_known_steps
	if new_steps > 0:
		_nurture.apply_steps(pet_data, new_steps)
		_last_known_steps = steps
		SaveManager.save_pet(pet_data)
		refresh()


## ヘルスケアデータ受信: 距離の差分をペットに反映
func _on_distance_updated(distance_m: float) -> void:
	if not pet_data:
		return
	var new_distance := distance_m - _last_known_distance
	if new_distance > 0.0:
		_nurture.apply_distance(pet_data, new_distance)
		_last_known_distance = distance_m
		SaveManager.save_pet(pet_data)
		refresh()


## ネイティブ連携の状態をバナーに表示
func _update_native_banner() -> void:
	var health_bridge: Node = DataManager._health_bridge
	var gps_bridge: Node = DataManager._gps_bridge
	var health_ok := health_bridge != null and health_bridge.is_available()
	var gps_ok := gps_bridge != null and gps_bridge.is_available()

	if health_ok and gps_ok:
		_native_banner.text = ""
	elif not health_ok and not gps_ok:
		_native_banner.text = "[Offline] ダミーデータで動作中"
	elif not health_ok:
		_native_banner.text = "[Offline] 歩数データは手動更新"
	else:
		_native_banner.text = "[Offline] 位置情報は利用不可"


## ネイティブ連携が利用可能なら今日のデータを取得
func _request_initial_health_data() -> void:
	var health_bridge: Node = DataManager._health_bridge
	if health_bridge and health_bridge.is_available():
		health_bridge.fetch_today_steps()
		health_bridge.fetch_today_distance()
		health_bridge.enable_background_delivery()

	var gps_bridge: Node = DataManager._gps_bridge
	if gps_bridge and gps_bridge.is_available():
		gps_bridge.start_tracking()


func _random_opponent_type() -> Enums.PetType:
	var types := [Enums.PetType.RUNNER, Enums.PetType.WALKER, Enums.PetType.SPRINTER]
	return types[randi() % types.size()]

extends Control
class_name BattleScreen

## オートバトル画面
## バトルエンジンの結果をターンごとにアニメーション表示する

signal battle_finished(result: Dictionary)

@onready var _pet_a_display: PetDisplay = %PetADisplay
@onready var _pet_b_display: PetDisplay = %PetBDisplay
@onready var _hp_bar_a: ProgressBar = %HpBarA
@onready var _hp_bar_b: ProgressBar = %HpBarB
@onready var _hp_label_a: Label = %HpLabelA
@onready var _hp_label_b: Label = %HpLabelB
@onready var _turn_label: Label = %TurnLabel
@onready var _action_label: Label = %ActionLabel
@onready var _result_panel: Panel = %ResultPanel
@onready var _result_label: Label = %ResultLabel
@onready var _continue_button: Button = %ContinueButton
@onready var _log_container: VBoxContainer = %LogContainer

var _engine: BattleEngine
var _battle_result: Dictionary
var _replay_index: int = 0
var _replay_timer: Timer


func _ready() -> void:
	_result_panel.visible = false
	_continue_button.pressed.connect(_on_continue_pressed)


## バトルを開始（即時全計算し、ログを順次再生）
func start_battle(pet_a: PetData, pet_b: PetData) -> void:
	_engine = BattleEngine.new()
	_engine.setup(pet_a, pet_b)

	_pet_a_display.setup(pet_a)
	_pet_b_display.setup(pet_b)

	_hp_bar_a.max_value = _engine.get_max_hp_a()
	_hp_bar_a.value = _engine.get_max_hp_a()
	_hp_bar_b.max_value = _engine.get_max_hp_b()
	_hp_bar_b.value = _engine.get_max_hp_b()
	_update_hp_labels()

	_turn_label.text = "Battle Start!"
	_action_label.text = ""

	# バトル計算を実行
	_battle_result = _engine.run_battle()

	# ログを順次再生
	_replay_index = 0
	_replay_timer = Timer.new()
	_replay_timer.wait_time = Constants.BATTLE_TURN_DURATION_SEC
	_replay_timer.timeout.connect(_replay_next_log)
	add_child(_replay_timer)
	_replay_timer.start()


func _replay_next_log() -> void:
	var log_lines: Array = _battle_result["log"]
	if _replay_index >= log_lines.size():
		_replay_timer.stop()
		_replay_timer.queue_free()
		_show_result()
		return

	var line: String = log_lines[_replay_index]
	_action_label.text = line
	_add_log_line(line)

	# HP バーを現在の状態に更新（ログ進行に合わせて段階的に）
	# 簡易実装: 最終HPに向かって補間
	var progress := float(_replay_index + 1) / float(maxi(log_lines.size(), 1))
	var target_hp_a: float = lerpf(float(_engine.get_max_hp_a()), float(_engine.get_hp_a()), progress)
	var target_hp_b: float = lerpf(float(_engine.get_max_hp_b()), float(_engine.get_hp_b()), progress)
	_hp_bar_a.value = target_hp_a
	_hp_bar_b.value = target_hp_b
	_update_hp_labels()

	# ターン表示を更新
	if line.begins_with("[Turn"):
		var turn_str := line.get_slice("]", 0).get_slice(" ", 1)
		_turn_label.text = "Turn %s" % turn_str

	_replay_index += 1


func _show_result() -> void:
	_hp_bar_a.value = _engine.get_hp_a()
	_hp_bar_b.value = _engine.get_hp_b()
	_update_hp_labels()

	_result_panel.visible = true
	var result_enum: Enums.BattleResult = _battle_result["result"]
	var winner: String = _battle_result["winner"]

	match result_enum:
		Enums.BattleResult.WIN:
			_result_label.text = "%s の勝利！" % winner
		Enums.BattleResult.LOSE:
			_result_label.text = "%s の勝利！" % winner
		Enums.BattleResult.DRAW:
			_result_label.text = "引き分け！"
		Enums.BattleResult.TIMEOUT:
			_result_label.text = "時間切れ！"


func _update_hp_labels() -> void:
	_hp_label_a.text = "%d / %d" % [int(_hp_bar_a.value), int(_hp_bar_a.max_value)]
	_hp_label_b.text = "%d / %d" % [int(_hp_bar_b.value), int(_hp_bar_b.max_value)]


func _add_log_line(text: String) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 14)
	_log_container.add_child(label)
	# スクロールを最下部に
	if _log_container.get_parent() is ScrollContainer:
		var scroll := _log_container.get_parent() as ScrollContainer
		await get_tree().process_frame
		scroll.scroll_vertical = scroll.get_v_scroll_bar().max_value


func _on_continue_pressed() -> void:
	battle_finished.emit(_battle_result)

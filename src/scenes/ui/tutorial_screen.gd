extends Control
class_name TutorialScreen

## 初回プレイ時のチュートリアル
## ステップ式でゲームの基本を説明する

signal completed

@onready var _title_label: Label = %TitleLabel
@onready var _body_label: Label = %BodyLabel
@onready var _step_label: Label = %StepLabel
@onready var _next_button: Button = %NextButton
@onready var _skip_button: Button = %SkipButton

var _current_step: int = 0

const STEP_KEYS: Array[Dictionary] = [
	{"title": "TUT_WELCOME_TITLE", "body": "TUT_WELCOME_BODY"},
	{"title": "TUT_NURTURE_TITLE", "body": "TUT_NURTURE_BODY"},
	{"title": "TUT_SKILL_TITLE", "body": "TUT_SKILL_BODY"},
	{"title": "TUT_BATTLE_TITLE", "body": "TUT_BATTLE_BODY"},
	{"title": "TUT_START_TITLE", "body": "TUT_START_BODY"},
]


func _ready() -> void:
	_next_button.pressed.connect(_on_next_pressed)
	_skip_button.pressed.connect(_on_skip_pressed)
	_show_step(0)


static func needs_tutorial() -> bool:
	var settings := SaveManager.load_settings()
	return not settings.get("tutorial_completed", false)


func _show_step(step: int) -> void:
	_current_step = step
	var data: Dictionary = STEP_KEYS[step]
	_title_label.text = tr(data["title"])
	_body_label.text = tr(data["body"])
	_step_label.text = "%d / %d" % [step + 1, STEP_KEYS.size()]

	if step >= STEP_KEYS.size() - 1:
		_next_button.text = tr("BEGIN")
	else:
		_next_button.text = tr("NEXT")


func _on_next_pressed() -> void:
	if _current_step >= STEP_KEYS.size() - 1:
		_finish()
	else:
		_show_step(_current_step + 1)


func _on_skip_pressed() -> void:
	_finish()


func _finish() -> void:
	var settings := SaveManager.load_settings()
	settings["tutorial_completed"] = true
	SaveManager.save_settings(settings)
	completed.emit()

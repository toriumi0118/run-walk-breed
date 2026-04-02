extends Control
class_name PermissionScreen

## 初回起動時の権限リクエスト画面
## HealthKit と Location の権限を順にリクエストする

signal permissions_completed

@onready var _title_label: Label = %TitleLabel
@onready var _description_label: Label = %DescriptionLabel
@onready var _health_button: Button = %HealthButton
@onready var _location_button: Button = %LocationButton
@onready var _skip_button: Button = %SkipButton
@onready var _health_status: Label = %HealthStatus
@onready var _location_status: Label = %LocationStatus

var _health_bridge: Node = null
var _gps_bridge: Node = null


func _ready() -> void:
	_health_button.pressed.connect(_on_health_pressed)
	_location_button.pressed.connect(_on_location_pressed)
	_skip_button.pressed.connect(_on_skip_pressed)

	# DataManager 経由でブリッジを取得
	_health_bridge = DataManager._health_bridge
	_gps_bridge = DataManager._gps_bridge

	_update_status()


## 権限が既に付与済みか判定（両方不要ならスキップ）
static func needs_permission_request() -> bool:
	var settings := SaveManager.load_settings()
	return not settings.get("permissions_requested", false)


func _on_health_pressed() -> void:
	if _health_bridge and _health_bridge.is_available():
		_health_bridge.permission_changed.connect(_on_health_permission_result, CONNECT_ONE_SHOT)
		_health_bridge.request_permission()
		_health_button.disabled = true
		_health_button.text = "リクエスト中..."
	else:
		_health_status.text = "（このデバイスでは利用不可）"
		_health_button.disabled = true


func _on_location_pressed() -> void:
	if _gps_bridge and _gps_bridge.is_available():
		_gps_bridge.permission_changed.connect(_on_location_permission_result, CONNECT_ONE_SHOT)
		_gps_bridge.request_permission()
		_location_button.disabled = true
		_location_button.text = "リクエスト中..."
	else:
		_location_status.text = "（このデバイスでは利用不可）"
		_location_button.disabled = true


func _on_skip_pressed() -> void:
	_save_permission_state()
	permissions_completed.emit()


func _on_health_permission_result(authorized: bool) -> void:
	if authorized:
		_health_status.text = "✓ 許可済み"
		_health_button.text = "許可済み"
	else:
		_health_status.text = "✗ 拒否（設定から変更可能）"
		_health_button.text = "拒否されました"
	_health_button.disabled = true
	_check_all_done()


func _on_location_permission_result(status: String) -> void:
	if status == "authorized" or status == "authorizedWhenInUse" or status == "authorizedAlways":
		_location_status.text = "✓ 許可済み"
		_location_button.text = "許可済み"
	else:
		_location_status.text = "✗ 拒否（設定から変更可能）"
		_location_button.text = "拒否されました"
	_location_button.disabled = true
	_check_all_done()


func _check_all_done() -> void:
	if _health_button.disabled and _location_button.disabled:
		_skip_button.text = "続ける"


func _update_status() -> void:
	var health_available := _health_bridge != null and _health_bridge.is_available()
	var gps_available := _gps_bridge != null and _gps_bridge.is_available()

	if not health_available:
		_health_status.text = "（このデバイスでは利用不可）"
		_health_button.disabled = true
	if not gps_available:
		_location_status.text = "（このデバイスでは利用不可）"
		_location_button.disabled = true

	# デスクトップ環境では両方使えないのでスキップ誘導
	if not health_available and not gps_available:
		_description_label.text = "デスクトップ環境ではネイティブ機能は利用できません。\nダミーデータで動作します。"
		_skip_button.text = "続ける"


func _save_permission_state() -> void:
	var settings := SaveManager.load_settings()
	settings["permissions_requested"] = true
	SaveManager.save_settings(settings)

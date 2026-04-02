extends Control
class_name MapScreen

## マップ画面
## map_bridge 経由で地図を表示し、現在地マーカーとルートを描画する

signal closed

@onready var _back_button: Button = %BackButton
@onready var _route_button: Button = %RouteButton
@onready var _clear_button: Button = %ClearButton
@onready var _status_label: Label = %StatusLabel
@onready var _coords_label: Label = %CoordsLabel
@onready var _map_area: Control = %MapArea

var _map_bridge: Node = null
var _is_showing_route: bool = false


func _ready() -> void:
	_back_button.pressed.connect(_on_back_pressed)
	_route_button.pressed.connect(_on_route_pressed)
	_clear_button.pressed.connect(_on_clear_pressed)

	_map_bridge = DataManager._load_bridge("res://src/native/map_bridge.gd")
	if _map_bridge:
		add_child(_map_bridge)

	DataManager.location_updated.connect(_on_location_updated)

	_initialize_map()


func _exit_tree() -> void:
	if DataManager.location_updated.is_connected(_on_location_updated):
		DataManager.location_updated.disconnect(_on_location_updated)
	if _map_bridge:
		_map_bridge.destroy()


func _initialize_map() -> void:
	if not _map_bridge or not _map_bridge.is_available():
		_status_label.text = "地図はこのデバイスでは利用できません"
		_route_button.disabled = true
		_clear_button.disabled = true
		return

	# MapArea の位置・サイズで WebView を初期化
	var rect := _map_area.get_global_rect()
	_map_bridge.initialize(rect.position.x, rect.position.y, rect.size.x, rect.size.y)

	# 現在地があればそこを表示、なければデフォルト（東京駅）
	var lat := DataManager.current_latitude
	var lon := DataManager.current_longitude
	if lat == 0.0 and lon == 0.0:
		lat = 35.6812
		lon = 139.7671
	_map_bridge.show_map(lat, lon, 15)
	_status_label.text = ""


func _on_location_updated(latitude: float, longitude: float) -> void:
	_coords_label.text = "%.4f, %.4f" % [latitude, longitude]
	if _map_bridge and _map_bridge.is_available():
		_map_bridge.update_marker(latitude, longitude)


func _on_route_pressed() -> void:
	if not _map_bridge or not _map_bridge.is_available():
		return
	var points := DataManager.route_points
	if points.is_empty():
		_status_label.text = "ルートデータがありません"
		return
	_map_bridge.show_route(points)
	_is_showing_route = true
	_status_label.text = "ルート表示中（%d ポイント）" % points.size()


func _on_clear_pressed() -> void:
	if _map_bridge and _map_bridge.is_available():
		_map_bridge.clear_route()
		_is_showing_route = false
		_status_label.text = ""


func _on_back_pressed() -> void:
	closed.emit()

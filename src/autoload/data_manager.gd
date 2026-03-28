extends Node

## ヘルスケアデータ・GPS データの取得と管理を行うシングルトン
## プラットフォーム別の実装は native/ 以下のブリッジを経由する

signal steps_updated(steps: int)
signal distance_updated(distance_m: float)
signal location_updated(latitude: float, longitude: float)

var total_steps: int = 0
var total_distance_m: float = 0.0
var current_latitude: float = 0.0
var current_longitude: float = 0.0
var route_points: Array[Vector2] = []

var _health_bridge: Node = null
var _gps_bridge: Node = null


func _ready() -> void:
	_init_bridges()


func _init_bridges() -> void:
	# プラットフォーム別のブリッジを初期化
	_health_bridge = _load_bridge("res://src/native/health_bridge.gd")
	_gps_bridge = _load_bridge("res://src/native/gps_bridge.gd")


func _load_bridge(path: String) -> Node:
	if ResourceLoader.exists(path):
		var script := load(path)
		var bridge := Node.new()
		bridge.set_script(script)
		add_child(bridge)
		return bridge
	return null


func update_steps(steps: int) -> void:
	total_steps = steps
	steps_updated.emit(steps)


func update_distance(distance_m: float) -> void:
	total_distance_m = distance_m
	distance_updated.emit(distance_m)


func update_location(latitude: float, longitude: float) -> void:
	current_latitude = latitude
	current_longitude = longitude
	route_points.append(Vector2(latitude, longitude))
	location_updated.emit(latitude, longitude)


## 2点間の距離を Haversine 式で計算（メートル）
static func haversine_distance(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
	const EARTH_RADIUS_M: float = 6371000.0
	var d_lat := deg_to_rad(lat2 - lat1)
	var d_lon := deg_to_rad(lon2 - lon1)
	var a := sin(d_lat / 2.0) * sin(d_lat / 2.0) + \
		cos(deg_to_rad(lat1)) * cos(deg_to_rad(lat2)) * \
		sin(d_lon / 2.0) * sin(d_lon / 2.0)
	var c := 2.0 * atan2(sqrt(a), sqrt(1.0 - a))
	return EARTH_RADIUS_M * c

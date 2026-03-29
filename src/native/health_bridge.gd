extends Node

## ヘルスケアデータ取得のプラットフォーム別ブリッジ
## Android: Health Connect（Android Plugin v2）
## iOS: HealthKit（SwiftGodot GDExtension）

signal steps_received(steps: int)
signal distance_received(distance_m: float)
signal permission_changed(authorized: bool)
signal error(message: String)

var _plugin: Object = null


func _ready() -> void:
	_init_plugin()


func _init_plugin() -> void:
	if OS.get_name() == "Android":
		if Engine.has_singleton("HealthConnectPlugin"):
			_plugin = Engine.get_singleton("HealthConnectPlugin")
	elif OS.get_name() == "iOS":
		if Engine.has_singleton("HealthKitPlugin"):
			_plugin = Engine.get_singleton("HealthKitPlugin")
			_plugin.connect("stepsUpdated", _on_steps_updated)
			_plugin.connect("distanceUpdated", _on_distance_updated)
			_plugin.connect("authorizationChanged", _on_authorization_changed)
			_plugin.connect("errorOccurred", _on_error)


func is_available() -> bool:
	return _plugin != null


func request_permission() -> void:
	if _plugin and _plugin.has_method("requestPermission"):
		_plugin.requestPermission()


func fetch_today_steps() -> void:
	if _plugin and _plugin.has_method("fetchTodaySteps"):
		_plugin.fetchTodaySteps()


func fetch_steps_for_days(days: int) -> void:
	if _plugin and _plugin.has_method("fetchStepsForDays"):
		_plugin.fetchStepsForDays(days)


func fetch_today_distance() -> void:
	if _plugin and _plugin.has_method("fetchTodayDistance"):
		_plugin.fetchTodayDistance()


func fetch_distance_for_days(days: int) -> void:
	if _plugin and _plugin.has_method("fetchDistanceForDays"):
		_plugin.fetchDistanceForDays(days)


func enable_background_delivery() -> void:
	if _plugin and _plugin.has_method("enableBackgroundDelivery"):
		_plugin.enableBackgroundDelivery()


# --- Signal handlers ---

func _on_steps_updated(steps: int) -> void:
	steps_received.emit(steps)
	DataManager.update_steps(steps)


func _on_distance_updated(distance_m: float) -> void:
	distance_received.emit(distance_m)
	DataManager.update_distance(distance_m)


func _on_authorization_changed(authorized: bool) -> void:
	permission_changed.emit(authorized)


func _on_error(message: String) -> void:
	error.emit(message)
	push_warning("HealthBridge error: %s" % message)

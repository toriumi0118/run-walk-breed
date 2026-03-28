extends Node

## ヘルスケアデータ取得のプラットフォーム別ブリッジ
## Android: Health Connect（Android Plugin v2）
## iOS: HealthKit（SwiftGodot GDExtension）

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


func is_available() -> bool:
	return _plugin != null


func request_permission() -> void:
	if _plugin and _plugin.has_method("requestPermission"):
		_plugin.requestPermission()


func fetch_steps() -> int:
	if _plugin and _plugin.has_method("getSteps"):
		return _plugin.getSteps()
	return 0


func fetch_distance() -> float:
	if _plugin and _plugin.has_method("getDistance"):
		return _plugin.getDistance()
	return 0.0

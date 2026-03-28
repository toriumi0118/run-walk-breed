extends Node

## GPS / 位置情報取得のプラットフォーム別ブリッジ
## Android: PraxisMapper GPS Plugin
## iOS: Core Location（SwiftGodot GDExtension）

signal location_received(latitude: float, longitude: float)

var _plugin: Object = null
var is_tracking: bool = false


func _ready() -> void:
	_init_plugin()


func _init_plugin() -> void:
	if OS.get_name() == "Android":
		if Engine.has_singleton("PraxisMapperGPSPlugin"):
			_plugin = Engine.get_singleton("PraxisMapperGPSPlugin")
			if _plugin.has_signal("onLocationUpdates"):
				_plugin.connect("onLocationUpdates", _on_location_update)
	elif OS.get_name() == "iOS":
		if Engine.has_singleton("CoreLocationPlugin"):
			_plugin = Engine.get_singleton("CoreLocationPlugin")


func is_available() -> bool:
	return _plugin != null


func start_tracking() -> void:
	if _plugin and _plugin.has_method("startTracking"):
		_plugin.startTracking()
		is_tracking = true


func stop_tracking() -> void:
	if _plugin and _plugin.has_method("stopTracking"):
		_plugin.stopTracking()
		is_tracking = false


func _on_location_update(latitude: float, longitude: float) -> void:
	location_received.emit(latitude, longitude)
	DataManager.update_location(latitude, longitude)

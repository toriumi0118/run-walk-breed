extends Node

## GPS / 位置情報取得のプラットフォーム別ブリッジ
## Android: PraxisMapper GPS Plugin
## iOS: Core Location（SwiftGodot GDExtension）

signal location_received(latitude: float, longitude: float, accuracy: float)
signal permission_changed(status: String)
signal error(message: String)

var _plugin: Object = null
var is_tracking: bool = false


func _ready() -> void:
	_init_plugin()


func _init_plugin() -> void:
	if OS.get_name() == "Android":
		if Engine.has_singleton("PraxisMapperGPSPlugin"):
			_plugin = Engine.get_singleton("PraxisMapperGPSPlugin")
			if _plugin.has_signal("onLocationUpdates"):
				_plugin.connect("onLocationUpdates", _on_location_update_android)
	elif OS.get_name() == "iOS":
		if Engine.has_singleton("LocationPlugin"):
			_plugin = Engine.get_singleton("LocationPlugin")
			_plugin.connect("locationUpdated", _on_location_update_ios)
			_plugin.connect("authorizationChanged", _on_authorization_changed)
			_plugin.connect("errorOccurred", _on_error)


func is_available() -> bool:
	return _plugin != null


func request_permission() -> void:
	if _plugin and _plugin.has_method("requestPermission"):
		_plugin.requestPermission()


func start_tracking() -> void:
	if _plugin and _plugin.has_method("startTracking"):
		_plugin.startTracking()
		is_tracking = true


func stop_tracking() -> void:
	if _plugin and _plugin.has_method("stopTracking"):
		_plugin.stopTracking()
		is_tracking = false


func enable_background_tracking() -> void:
	if _plugin and _plugin.has_method("enableBackgroundTracking"):
		_plugin.enableBackgroundTracking()


func set_distance_filter(meters: float) -> void:
	if _plugin and _plugin.has_method("setDistanceFilter"):
		_plugin.setDistanceFilter(meters)


# --- Signal handlers ---

func _on_location_update_android(latitude: float, longitude: float) -> void:
	location_received.emit(latitude, longitude, 0.0)
	DataManager.update_location(latitude, longitude)


func _on_location_update_ios(latitude: float, longitude: float, accuracy: float) -> void:
	location_received.emit(latitude, longitude, accuracy)
	DataManager.update_location(latitude, longitude)


func _on_authorization_changed(status: String) -> void:
	permission_changed.emit(status)


func _on_error(message: String) -> void:
	error.emit(message)
	push_warning("GPSBridge error: %s" % message)

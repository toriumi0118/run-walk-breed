extends Node

## 地図表示のブリッジ
## Android: godot-webview
## iOS: MapViewPlugin（SwiftGodot + WKWebView + Leaflet/OSM）

signal map_ready
signal error(message: String)

var _plugin: Object = null
var is_visible: bool = false


func _ready() -> void:
	_init_plugin()


func _init_plugin() -> void:
	if OS.get_name() == "Android":
		if Engine.has_singleton("GodotWebView"):
			_plugin = Engine.get_singleton("GodotWebView")
	elif OS.get_name() == "iOS":
		if Engine.has_singleton("MapViewPlugin"):
			_plugin = Engine.get_singleton("MapViewPlugin")
			_plugin.connect("mapReady", _on_map_ready)
			_plugin.connect("errorOccurred", _on_error)


func is_available() -> bool:
	return _plugin != null


## 地図の WebView を初期化（位置とサイズを指定）
func initialize(x: float, y: float, width: float, height: float) -> void:
	if _plugin and _plugin.has_method("initialize"):
		_plugin.initialize(x, y, width, height)


## 指定座標で地図を表示
func show_map(latitude: float, longitude: float, zoom: int = 15) -> void:
	if not _plugin:
		return

	if OS.get_name() == "iOS":
		if _plugin.has_method("showMap"):
			_plugin.showMap(latitude, longitude, zoom)
			is_visible = true
	else:
		# Android: WebView に HTML を直接ロード
		# TODO: Android 実装
		pass


## 地図を非表示
func hide_map() -> void:
	if _plugin and _plugin.has_method("hide"):
		_plugin.hide()
		is_visible = false


## 地図を表示
func show() -> void:
	if _plugin and _plugin.has_method("show"):
		_plugin.show()
		is_visible = true


## 現在地マーカーを更新
func update_marker(latitude: float, longitude: float) -> void:
	if _plugin and _plugin.has_method("updateMarker"):
		_plugin.updateMarker(latitude, longitude)


## 中心座標を移動
func set_center(latitude: float, longitude: float) -> void:
	if _plugin and _plugin.has_method("setCenter"):
		_plugin.setCenter(latitude, longitude)


## ルートをポリラインで描画
func show_route(points: Array[Vector2]) -> void:
	if not _plugin:
		return
	# Vector2 配列を JSON 配列に変換（[lat, lng] の配列）
	var json_points: Array = []
	for point in points:
		json_points.append([point.x, point.y])
	var json_str := JSON.stringify(json_points)
	if _plugin.has_method("drawRoute"):
		_plugin.drawRoute(json_str)


## ルートをクリア
func clear_route() -> void:
	if _plugin and _plugin.has_method("clearRoute"):
		_plugin.clearRoute()


## WebView を破棄
func destroy() -> void:
	if _plugin and _plugin.has_method("destroy"):
		_plugin.destroy()
		is_visible = false


# --- Signal handlers ---

func _on_map_ready() -> void:
	map_ready.emit()


func _on_error(message: String) -> void:
	error.emit(message)
	push_warning("MapBridge error: %s" % message)

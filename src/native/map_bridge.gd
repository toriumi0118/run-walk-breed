extends Node

## 地図表示のブリッジ
## WebView overlay を使用して Google Maps / OpenStreetMap を表示

var _webview: Object = null
var is_visible: bool = false


func _ready() -> void:
	_init_webview()


func _init_webview() -> void:
	if OS.get_name() == "Android":
		if Engine.has_singleton("GodotWebView"):
			_webview = Engine.get_singleton("GodotWebView")
	# iOS: WKWebView wrapper（カスタムプラグインで対応）


func is_available() -> bool:
	return _webview != null


func show_map(latitude: float, longitude: float, zoom: int = 15) -> void:
	if not _webview:
		return
	# TODO: HTML テンプレートに座標を埋め込んで WebView に表示
	is_visible = true


func hide_map() -> void:
	if not _webview:
		return
	is_visible = false


func show_route(points: Array[Vector2]) -> void:
	if not _webview:
		return
	# TODO: ルートポイントを JS 経由で地図上にポリラインとして描画
	pass

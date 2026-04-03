extends CanvasLayer
class_name ScreenTransition

## 画面遷移アニメーション（フェードイン/アウト）
## Autoload として登録して使う

signal transition_midpoint
signal transition_finished

var _color_rect: ColorRect
var _tween: Tween

const FADE_DURATION: float = 0.3


func _ready() -> void:
	layer = 100
	_color_rect = ColorRect.new()
	_color_rect.color = Color(0, 0, 0, 0)
	_color_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_color_rect)


## フェードアウト → コールバック → フェードイン
func transition(callable: Callable) -> void:
	_color_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(_color_rect, "color:a", 1.0, FADE_DURATION)
	_tween.tween_callback(func() -> void:
		transition_midpoint.emit()
		callable.call()
	)
	_tween.tween_property(_color_rect, "color:a", 0.0, FADE_DURATION)
	_tween.tween_callback(func() -> void:
		_color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		transition_finished.emit()
	)


## フェードインのみ（画面表示時）
func fade_in() -> void:
	_color_rect.color.a = 1.0
	_color_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(_color_rect, "color:a", 0.0, FADE_DURATION)
	_tween.tween_callback(func() -> void:
		_color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		transition_finished.emit()
	)


## フェードアウトのみ（画面非表示時）
func fade_out() -> void:
	_color_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(_color_rect, "color:a", 1.0, FADE_DURATION)
	_tween.tween_callback(func() -> void:
		transition_finished.emit()
	)

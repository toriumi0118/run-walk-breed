extends Control
class_name PetDisplay

## ペットのビジュアル表示コンポーネント
## プレースホルダー: 色付き円 + タイプ名ラベル
## 将来的には @export var sprite_texture を差し替えるだけで実アセットに切り替え可能

signal pressed

@export var sprite_texture: Texture2D = null  # 実アセット差し替え用
@export var display_size: Vector2 = Vector2(120, 120)

var pet_data: PetData = null

@onready var _body: ColorRect = %Body
@onready var _name_label: Label = %NameLabel
@onready var _type_label: Label = %TypeLabel
@onready var _level_label: Label = %LevelLabel
@onready var _sprite: Sprite2D = %Sprite


func setup(data: PetData) -> void:
	pet_data = data
	_refresh()


func _refresh() -> void:
	if not pet_data or not is_node_ready():
		return

	_name_label.text = pet_data.pet_name
	_type_label.text = _type_string(pet_data.pet_type)
	_level_label.text = "Lv.%d" % pet_data.level
	_body.color = _type_color(pet_data.pet_type)

	if sprite_texture:
		_sprite.texture = sprite_texture
		_sprite.visible = true
		_body.visible = false
	else:
		_sprite.visible = false
		_body.visible = true


func _type_string(pet_type: Enums.PetType) -> String:
	match pet_type:
		Enums.PetType.RUNNER:
			return "Runner"
		Enums.PetType.WALKER:
			return "Walker"
		Enums.PetType.SPRINTER:
			return "Sprinter"
	return "Unknown"


func _type_color(pet_type: Enums.PetType) -> Color:
	match pet_type:
		Enums.PetType.RUNNER:
			return Color(0.2, 0.6, 1.0)     # 青
		Enums.PetType.WALKER:
			return Color(0.3, 0.8, 0.3)     # 緑
		Enums.PetType.SPRINTER:
			return Color(1.0, 0.4, 0.3)     # 赤
	return Color.WHITE

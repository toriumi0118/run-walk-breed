extends Control
class_name SkillEditScreen

## スキル編成画面
## 習得済みスキルから最大 4 つを装備スロットにセットする

signal closed

@onready var _equipped_container: HBoxContainer = %EquippedContainer
@onready var _learned_container: VBoxContainer = %LearnedContainer
@onready var _back_button: Button = %BackButton
@onready var _info_label: Label = %InfoLabel

var _pet_data: PetData


func _ready() -> void:
	_back_button.pressed.connect(func() -> void: closed.emit())


func setup(data: PetData) -> void:
	_pet_data = data
	_refresh()


func _refresh() -> void:
	if not _pet_data or not is_node_ready():
		return

	# 装備スロット表示をクリア＆再生成
	for child in _equipped_container.get_children():
		child.queue_free()

	for i in range(Constants.MAX_SKILL_SLOTS):
		var slot := _create_slot(i)
		_equipped_container.add_child(slot)

	# 習得済みスキル一覧をクリア＆再生成
	for child in _learned_container.get_children():
		child.queue_free()

	for skill in _pet_data.learned_skills:
		var row := _create_skill_row(skill)
		_learned_container.add_child(row)

	_info_label.text = "Equipped: %d / %d" % [_pet_data.equipped_skills.size(), Constants.MAX_SKILL_SLOTS]


func _create_slot(index: int) -> Panel:
	var panel := Panel.new()
	panel.custom_minimum_size = Vector2(100, 100)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(vbox)

	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	if index < _pet_data.equipped_skills.size():
		var skill := _pet_data.equipped_skills[index]
		label.text = skill.skill_name

		var remove_btn := Button.new()
		remove_btn.text = "Remove"
		remove_btn.custom_minimum_size = Vector2(0, 32)
		remove_btn.pressed.connect(func() -> void:
			_pet_data.unequip_skill(skill)
			_refresh()
		)
		vbox.add_child(label)
		vbox.add_child(remove_btn)
	else:
		label.text = "---"
		vbox.add_child(label)

	return panel


func _create_skill_row(skill: SkillData) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, 48)

	# スキル名
	var name_label := Label.new()
	name_label.text = skill.skill_name
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(name_label)

	# タイプ
	var type_label := Label.new()
	type_label.text = _skill_type_string(skill.skill_type)
	type_label.custom_minimum_size = Vector2(80, 0)
	row.add_child(type_label)

	# 威力
	var power_label := Label.new()
	power_label.text = "Pow:%d" % skill.power if skill.power > 0 else ""
	power_label.custom_minimum_size = Vector2(70, 0)
	row.add_child(power_label)

	# 装備/解除ボタン
	var is_equipped := _is_skill_equipped(skill)
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(80, 0)
	if is_equipped:
		btn.text = "Equipped"
		btn.disabled = true
	else:
		btn.text = "Equip"
		btn.disabled = _pet_data.equipped_skills.size() >= Constants.MAX_SKILL_SLOTS
		btn.pressed.connect(func() -> void:
			_pet_data.equip_skill(skill)
			_refresh()
		)
	row.add_child(btn)

	return row


func _is_skill_equipped(skill: SkillData) -> bool:
	for s in _pet_data.equipped_skills:
		if s.skill_name == skill.skill_name:
			return true
	return false


func _skill_type_string(skill_type: SkillData.SkillType) -> String:
	match skill_type:
		SkillData.SkillType.ATTACK:
			return "ATK"
		SkillData.SkillType.BUFF:
			return "BUFF"
		SkillData.SkillType.DEBUFF:
			return "DEBUF"
		SkillData.SkillType.HEAL:
			return "HEAL"
	return "?"

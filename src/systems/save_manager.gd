class_name SaveManager
extends RefCounted

## ローカルセーブ/ロード機構
## JSON 形式でペットデータ、設定等を永続化する

const SAVE_PATH: String = "user://save_data.json"
const SETTINGS_PATH: String = "user://settings.json"


## ペットデータをセーブ
static func save_pet(pet: PetData) -> void:
	var data := {
		"pet_name": pet.pet_name,
		"pet_type": pet.pet_type,
		"level": pet.level,
		"experience": pet.experience,
		"total_steps": pet.total_steps,
		"total_distance_m": pet.total_distance_m,
		"base_hp": pet.base_hp,
		"base_attack": pet.base_attack,
		"base_defense": pet.base_defense,
		"base_speed": pet.base_speed,
		"learned_skills": _skills_to_array(pet.learned_skills),
		"equipped_skills": _skills_to_array(pet.equipped_skills),
	}

	var json_str := JSON.stringify(data, "\t")
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(json_str)


## ペットデータをロード（存在しなければ null）
static func load_pet() -> PetData:
	if not FileAccess.file_exists(SAVE_PATH):
		return null

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return null

	var json_str := file.get_as_text()
	var json := JSON.new()
	if json.parse(json_str) != OK:
		return null

	var data: Dictionary = json.data
	var pet := PetData.new()
	pet.pet_name = data.get("pet_name", "")
	pet.pet_type = data.get("pet_type", Enums.PetType.RUNNER) as Enums.PetType
	pet.level = data.get("level", 1)
	pet.experience = data.get("experience", 0)
	pet.total_steps = data.get("total_steps", 0)
	pet.total_distance_m = data.get("total_distance_m", 0.0)
	pet.base_hp = data.get("base_hp", 100)
	pet.base_attack = data.get("base_attack", 10)
	pet.base_defense = data.get("base_defense", 10)
	pet.base_speed = data.get("base_speed", 10)

	# スキルはマスタデータから名前で復元
	pet.learned_skills = _array_to_skills(data.get("learned_skills", []))
	pet.equipped_skills = _array_to_skills(data.get("equipped_skills", []))

	return pet


## セーブデータが存在するか
static func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


## セーブデータを削除
static func delete_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)


## 設定をセーブ
static func save_settings(settings: Dictionary) -> void:
	var json_str := JSON.stringify(settings, "\t")
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if file:
		file.store_string(json_str)


## 設定をロード
static func load_settings() -> Dictionary:
	if not FileAccess.file_exists(SETTINGS_PATH):
		return _default_settings()

	var file := FileAccess.open(SETTINGS_PATH, FileAccess.READ)
	if not file:
		return _default_settings()

	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		return _default_settings()

	return json.data


static func _default_settings() -> Dictionary:
	return {
		"bgm_volume": 0.8,
		"sfx_volume": 1.0,
		"notifications": true,
	}


static func _skills_to_array(skills: Array[SkillData]) -> Array:
	var result: Array = []
	for skill in skills:
		result.append(skill.skill_name)
	return result


static func _array_to_skills(names: Array) -> Array[SkillData]:
	var result: Array[SkillData] = []
	var all_skills := SkillDatabase.get_all_skills()
	for skill_name in names:
		for skill in all_skills:
			if skill.skill_name == skill_name:
				result.append(skill)
				break
	return result

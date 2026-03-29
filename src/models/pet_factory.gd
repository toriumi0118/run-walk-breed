class_name PetFactory
extends RefCounted

## ペットの生成ファクトリ

static func create(pet_name: String, pet_type: Enums.PetType) -> PetData:
	var pet := PetData.new()
	pet.pet_name = pet_name
	pet.pet_type = pet_type
	pet.level = 1
	pet.experience = 0

	var base: Dictionary = _base_stats_for_type(pet_type)
	pet.base_hp = base["hp"]
	pet.base_attack = base["attack"]
	pet.base_defense = base["defense"]
	pet.base_speed = base["speed"]

	# 初期スキルを習得・装備
	var starter_skills := SkillDatabase.get_starter_skills(pet_type)
	for skill in starter_skills:
		pet.learn_skill(skill)
		pet.equip_skill(skill)

	return pet


static func _base_stats_for_type(pet_type: Enums.PetType) -> Dictionary:
	match pet_type:
		Enums.PetType.RUNNER:
			return {"hp": 90, "attack": 10, "defense": 8, "speed": 14}
		Enums.PetType.WALKER:
			return {"hp": 120, "attack": 9, "defense": 12, "speed": 9}
		Enums.PetType.SPRINTER:
			return {"hp": 80, "attack": 14, "defense": 7, "speed": 12}
	return Constants.BASE_PET_STATS

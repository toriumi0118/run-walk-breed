extends GdUnitTestSuite

## PetData のユニットテスト


func test_initial_stats() -> void:
	var pet := PetData.new()
	pet.pet_name = "TestPet"
	pet.pet_type = Enums.PetType.RUNNER
	pet.level = 1
	pet.base_hp = 100
	pet.base_attack = 10
	pet.base_defense = 10
	pet.base_speed = 10

	assert_int(pet.get_max_hp()).is_equal(100)
	assert_int(pet.get_attack()).is_equal(10)
	assert_int(pet.get_defense()).is_equal(10)
	assert_int(pet.get_speed()).is_equal(10)


func test_runner_growth_rates() -> void:
	var pet := PetData.new()
	pet.pet_type = Enums.PetType.RUNNER
	pet.level = 11
	pet.base_hp = 100
	pet.base_attack = 10
	pet.base_defense = 10
	pet.base_speed = 10

	# Runner: HP+8, ATK+3, DEF+2, SPD+5 per level
	assert_int(pet.get_max_hp()).is_equal(100 + 10 * 8)
	assert_int(pet.get_attack()).is_equal(10 + 10 * 3)
	assert_int(pet.get_defense()).is_equal(10 + 10 * 2)
	assert_int(pet.get_speed()).is_equal(10 + 10 * 5)


func test_walker_growth_rates() -> void:
	var pet := PetData.new()
	pet.pet_type = Enums.PetType.WALKER
	pet.level = 11
	pet.base_hp = 100
	pet.base_attack = 10
	pet.base_defense = 10
	pet.base_speed = 10

	# Walker: HP+10, ATK+3, DEF+4, SPD+3 per level
	assert_int(pet.get_max_hp()).is_equal(100 + 10 * 10)
	assert_int(pet.get_attack()).is_equal(10 + 10 * 3)
	assert_int(pet.get_defense()).is_equal(10 + 10 * 4)
	assert_int(pet.get_speed()).is_equal(10 + 10 * 3)


func test_sprinter_growth_rates() -> void:
	var pet := PetData.new()
	pet.pet_type = Enums.PetType.SPRINTER
	pet.level = 11
	pet.base_hp = 100
	pet.base_attack = 10
	pet.base_defense = 10
	pet.base_speed = 10

	# Sprinter: HP+6, ATK+5, DEF+2, SPD+4 per level
	assert_int(pet.get_max_hp()).is_equal(100 + 10 * 6)
	assert_int(pet.get_attack()).is_equal(10 + 10 * 5)
	assert_int(pet.get_defense()).is_equal(10 + 10 * 2)
	assert_int(pet.get_speed()).is_equal(10 + 10 * 4)


func test_add_experience_level_up() -> void:
	var pet := PetData.new()
	pet.level = 1
	pet.experience = 0

	# Lv1 needs 1000 EXP to level up
	pet.add_experience(1000)
	assert_int(pet.level).is_equal(2)
	assert_int(pet.experience).is_equal(0)


func test_add_experience_multi_level() -> void:
	var pet := PetData.new()
	pet.level = 1
	pet.experience = 0

	# Lv1=1000, Lv2=2000 → 3000 total should reach Lv3
	pet.add_experience(3000)
	assert_int(pet.level).is_equal(3)
	assert_int(pet.experience).is_equal(0)


func test_add_experience_max_level() -> void:
	var pet := PetData.new()
	pet.level = Constants.MAX_PET_LEVEL
	pet.experience = 0

	pet.add_experience(99999)
	assert_int(pet.level).is_equal(Constants.MAX_PET_LEVEL)
	assert_int(pet.experience).is_equal(0)


func test_learn_skill() -> void:
	var pet := PetData.new()
	var skill := SkillData.new()
	skill.skill_name = "TestSkill"

	assert_bool(pet.learn_skill(skill)).is_true()
	assert_int(pet.learned_skills.size()).is_equal(1)


func test_learn_duplicate_skill() -> void:
	var pet := PetData.new()
	var skill := SkillData.new()
	skill.skill_name = "TestSkill"

	pet.learn_skill(skill)
	assert_bool(pet.learn_skill(skill)).is_false()
	assert_int(pet.learned_skills.size()).is_equal(1)


func test_equip_skill() -> void:
	var pet := PetData.new()
	var skill := SkillData.new()
	skill.skill_name = "TestSkill"

	assert_bool(pet.equip_skill(skill)).is_true()
	assert_int(pet.equipped_skills.size()).is_equal(1)


func test_equip_max_skills() -> void:
	var pet := PetData.new()
	for i in range(Constants.MAX_SKILL_SLOTS):
		var s := SkillData.new()
		s.skill_name = "Skill%d" % i
		pet.equip_skill(s)

	var extra := SkillData.new()
	extra.skill_name = "Extra"
	assert_bool(pet.equip_skill(extra)).is_false()
	assert_int(pet.equipped_skills.size()).is_equal(Constants.MAX_SKILL_SLOTS)


func test_unequip_skill() -> void:
	var pet := PetData.new()
	var skill := SkillData.new()
	skill.skill_name = "TestSkill"
	pet.equip_skill(skill)

	pet.unequip_skill(skill)
	assert_int(pet.equipped_skills.size()).is_equal(0)

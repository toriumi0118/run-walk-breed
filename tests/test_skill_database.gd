extends GdUnitTestSuite

## SkillDatabase のユニットテスト


func test_all_skills_exist() -> void:
	var skills := SkillDatabase.get_all_skills()
	# 13 skills defined
	assert_int(skills.size()).is_equal(13)


func test_all_skills_have_names() -> void:
	var skills := SkillDatabase.get_all_skills()
	for skill in skills:
		assert_str(skill.skill_name).is_not_empty()


func test_starter_skills_runner() -> void:
	var starters := SkillDatabase.get_starter_skills(Enums.PetType.RUNNER)
	# タックル（共通Lv1）が含まれるはず
	var has_tackle := false
	for skill in starters:
		if skill.skill_name == "タックル":
			has_tackle = true
	assert_bool(has_tackle).is_true()
	assert_int(starters.size()).is_greater(0)


func test_starter_skills_walker() -> void:
	var starters := SkillDatabase.get_starter_skills(Enums.PetType.WALKER)
	assert_int(starters.size()).is_greater(0)


func test_starter_skills_sprinter() -> void:
	var starters := SkillDatabase.get_starter_skills(Enums.PetType.SPRINTER)
	assert_int(starters.size()).is_greater(0)


func test_learnable_skills_level_3_runner() -> void:
	var skills := SkillDatabase.get_learnable_skills(Enums.PetType.RUNNER, 3)
	# Runner gets クイックダッシュ at Lv3
	var found := false
	for skill in skills:
		if skill.skill_name == "クイックダッシュ":
			found = true
	assert_bool(found).is_true()


func test_no_cross_type_skills() -> void:
	# Runner should not get Walker-only skills
	var walker_skills := SkillDatabase.get_learnable_skills(Enums.PetType.WALKER, 3)
	for skill in walker_skills:
		if not skill.any_type:
			assert_int(skill.required_type).is_equal(Enums.PetType.WALKER)


func test_skill_types_valid() -> void:
	var skills := SkillDatabase.get_all_skills()
	for skill in skills:
		assert_bool(
			skill.skill_type == SkillData.SkillType.ATTACK or
			skill.skill_type == SkillData.SkillType.BUFF or
			skill.skill_type == SkillData.SkillType.DEBUFF or
			skill.skill_type == SkillData.SkillType.HEAL
		).is_true()


func test_attack_skills_have_power() -> void:
	var skills := SkillDatabase.get_all_skills()
	for skill in skills:
		if skill.skill_type == SkillData.SkillType.ATTACK:
			assert_int(skill.power).is_greater(0)
			assert_int(skill.accuracy).is_greater(0)

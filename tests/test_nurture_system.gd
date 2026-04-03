extends GdUnitTestSuite

## NurtureSystem のユニットテスト


func test_apply_steps_adds_exp() -> void:
	var pet := PetFactory.create("TestPet", Enums.PetType.RUNNER)
	var nurture := NurtureSystem.new()
	var result := nurture.apply_steps(pet, 500)

	assert_int(result["exp_gained"]).is_equal(500)
	assert_int(pet.total_steps).is_equal(500)


func test_apply_steps_causes_level_up() -> void:
	var pet := PetFactory.create("TestPet", Enums.PetType.RUNNER)
	var nurture := NurtureSystem.new()
	var result := nurture.apply_steps(pet, 1000)

	assert_int(result["levels_gained"]).is_equal(1)
	assert_int(pet.level).is_equal(2)


func test_apply_steps_zero() -> void:
	var pet := PetFactory.create("TestPet", Enums.PetType.WALKER)
	var nurture := NurtureSystem.new()
	var result := nurture.apply_steps(pet, 0)

	assert_int(result["exp_gained"]).is_equal(0)
	assert_int(pet.total_steps).is_equal(0)


func test_apply_steps_negative() -> void:
	var pet := PetFactory.create("TestPet", Enums.PetType.WALKER)
	var nurture := NurtureSystem.new()
	var result := nurture.apply_steps(pet, -100)

	assert_int(result["exp_gained"]).is_equal(0)


func test_apply_distance_adds_exp() -> void:
	var pet := PetFactory.create("TestPet", Enums.PetType.SPRINTER)
	var nurture := NurtureSystem.new()
	var result := nurture.apply_distance(pet, 500.0)

	# 500m / 100 * 10 = 50 EXP
	assert_int(result["exp_gained"]).is_equal(50)
	assert_float(pet.total_distance_m).is_equal(500.0)


func test_apply_steps_learns_skills() -> void:
	var pet := PetFactory.create("TestPet", Enums.PetType.RUNNER)
	var nurture := NurtureSystem.new()

	# Lv3 でクイックダッシュを覚えるはず
	nurture.apply_steps(pet, 6000)  # Lv1→Lv3 以上

	var has_quick_dash := false
	for skill in pet.learned_skills:
		if skill.skill_name == "クイックダッシュ":
			has_quick_dash = true
			break
	assert_bool(has_quick_dash).is_true()


func test_multi_level_up() -> void:
	var pet := PetFactory.create("TestPet", Enums.PetType.RUNNER)
	var nurture := NurtureSystem.new()
	# Lv1=1000, Lv2=2000, Lv3=3000 → 6000 total
	var result := nurture.apply_steps(pet, 6000)

	assert_int(pet.level).is_equal(4)
	assert_int(result["levels_gained"]).is_equal(3)

extends GdUnitTestSuite

## BattleEngine のユニットテスト


func _create_pet(pname: String, ptype: Enums.PetType, level: int) -> PetData:
	var pet := PetFactory.create(pname, ptype)
	if level > 1:
		var nurture := NurtureSystem.new()
		nurture.apply_steps(pet, (level - 1) * Constants.STEPS_PER_LEVEL_UP)
	return pet


func test_battle_produces_result() -> void:
	var pet_a := _create_pet("PetA", Enums.PetType.RUNNER, 5)
	var pet_b := _create_pet("PetB", Enums.PetType.WALKER, 5)

	var engine := BattleEngine.new()
	engine.setup(pet_a, pet_b)
	var result := engine.run_battle()

	assert_bool(result.has("result")).is_true()
	assert_bool(result.has("winner")).is_true()
	assert_bool(result.has("turns")).is_true()
	assert_bool(result.has("log")).is_true()
	assert_int(result["turns"]).is_greater(0)


func test_battle_result_is_valid_enum() -> void:
	var pet_a := _create_pet("PetA", Enums.PetType.RUNNER, 5)
	var pet_b := _create_pet("PetB", Enums.PetType.SPRINTER, 5)

	var engine := BattleEngine.new()
	engine.setup(pet_a, pet_b)
	var result := engine.run_battle()

	var battle_result: Enums.BattleResult = result["result"]
	assert_bool(
		battle_result == Enums.BattleResult.WIN or
		battle_result == Enums.BattleResult.LOSE or
		battle_result == Enums.BattleResult.DRAW or
		battle_result == Enums.BattleResult.TIMEOUT
	).is_true()


func test_battle_max_turns() -> void:
	var pet_a := _create_pet("PetA", Enums.PetType.RUNNER, 5)
	var pet_b := _create_pet("PetB", Enums.PetType.WALKER, 5)

	var engine := BattleEngine.new()
	engine.setup(pet_a, pet_b)
	var result := engine.run_battle()

	assert_int(result["turns"]).is_less_equal(Constants.MAX_BATTLE_TURNS)


func test_battle_hp_not_negative() -> void:
	var pet_a := _create_pet("PetA", Enums.PetType.SPRINTER, 10)
	var pet_b := _create_pet("PetB", Enums.PetType.RUNNER, 3)

	var engine := BattleEngine.new()
	engine.setup(pet_a, pet_b)
	engine.run_battle()

	assert_int(engine.get_hp_a()).is_greater_equal(0)
	assert_int(engine.get_hp_b()).is_greater_equal(0)


func test_battle_without_skills() -> void:
	var pet_a := PetData.new()
	pet_a.pet_name = "NoSkills"
	pet_a.pet_type = Enums.PetType.RUNNER
	pet_a.base_hp = 100
	pet_a.base_attack = 10
	pet_a.base_defense = 10
	pet_a.base_speed = 10

	var pet_b := _create_pet("PetB", Enums.PetType.WALKER, 5)

	var engine := BattleEngine.new()
	engine.setup(pet_a, pet_b)
	var result := engine.run_battle()

	# スキルなしでもバトルは正常終了する
	assert_bool(result.has("result")).is_true()


func test_battle_log_not_empty() -> void:
	var pet_a := _create_pet("PetA", Enums.PetType.RUNNER, 5)
	var pet_b := _create_pet("PetB", Enums.PetType.WALKER, 5)

	var engine := BattleEngine.new()
	engine.setup(pet_a, pet_b)
	var result := engine.run_battle()

	var log_lines: Array = result["log"]
	assert_int(log_lines.size()).is_greater(0)

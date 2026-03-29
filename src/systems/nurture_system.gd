class_name NurtureSystem
extends RefCounted

## 育成システム
## 歩数・距離を経験値に変換し、レベルアップとスキル習得を処理する

signal pet_leveled_up(pet: PetData, new_level: int)
signal pet_learned_skill(pet: PetData, skill: SkillData)

# 歩数 → 経験値の変換レート
const EXP_PER_STEP: float = 1.0
# 距離（メートル） → ボーナス経験値
const EXP_PER_100M: float = 10.0


## 歩数を反映し、経験値・レベルアップ・スキル習得を処理
func apply_steps(pet: PetData, new_steps: int) -> Dictionary:
	var result := {
		"exp_gained": 0,
		"levels_gained": 0,
		"skills_learned": [] as Array[SkillData],
	}

	if new_steps <= 0:
		return result

	var old_level := pet.level
	var exp_gained := int(new_steps * EXP_PER_STEP)
	pet.add_experience(exp_gained)
	pet.total_steps += new_steps
	result["exp_gained"] = exp_gained
	result["levels_gained"] = pet.level - old_level

	# レベルアップ中に習得可能なスキルをチェック
	for lv in range(old_level + 1, pet.level + 1):
		var new_skills := SkillDatabase.get_learnable_skills(pet.pet_type, lv)
		for skill in new_skills:
			if pet.learn_skill(skill):
				result["skills_learned"].append(skill)

	return result


## 距離を反映（歩数とは別にボーナス経験値）
func apply_distance(pet: PetData, distance_m: float) -> Dictionary:
	var result := {
		"exp_gained": 0,
		"levels_gained": 0,
		"skills_learned": [] as Array[SkillData],
	}

	if distance_m <= 0.0:
		return result

	var old_level := pet.level
	var exp_gained := int(distance_m / 100.0 * EXP_PER_100M)
	pet.add_experience(exp_gained)
	pet.total_distance_m += distance_m
	result["exp_gained"] = exp_gained
	result["levels_gained"] = pet.level - old_level

	for lv in range(old_level + 1, pet.level + 1):
		var new_skills := SkillDatabase.get_learnable_skills(pet.pet_type, lv)
		for skill in new_skills:
			if pet.learn_skill(skill):
				result["skills_learned"].append(skill)

	return result

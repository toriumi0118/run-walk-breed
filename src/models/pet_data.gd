extends Resource
class_name PetData

## ペットの全データを保持する Resource クラス
## セーブ/ロード、インスペクタ編集に対応

signal level_changed(new_level: int)
signal skill_learned(skill: SkillData)

@export var pet_name: String = ""
@export var pet_type: Enums.PetType = Enums.PetType.RUNNER

# レベル・経験値
@export var level: int = 1
@export var experience: int = 0
@export var total_steps: int = 0
@export var total_distance_m: float = 0.0

# 基礎ステータス（レベルアップで成長）
@export var base_hp: int = 100
@export var base_attack: int = 10
@export var base_defense: int = 10
@export var base_speed: int = 10

# 習得済みスキル（全て）
@export var learned_skills: Array[SkillData] = []

# バトル用にセットしたスキル（最大 MAX_SKILL_SLOTS）
@export var equipped_skills: Array[SkillData] = []


## 現在の最大 HP（レベル補正込み）
func get_max_hp() -> int:
	return base_hp + (level - 1) * _growth_rate("hp")


## 現在の攻撃力（レベル補正込み）
func get_attack() -> int:
	return base_attack + (level - 1) * _growth_rate("attack")


## 現在の防御力（レベル補正込み）
func get_defense() -> int:
	return base_defense + (level - 1) * _growth_rate("defense")


## 現在の素早さ（レベル補正込み）
func get_speed() -> int:
	return base_speed + (level - 1) * _growth_rate("speed")


## 次のレベルアップに必要な経験値
func get_exp_to_next_level() -> int:
	return level * Constants.STEPS_PER_LEVEL_UP


## 経験値を加算し、必要ならレベルアップ
func add_experience(amount: int) -> void:
	if level >= Constants.MAX_PET_LEVEL:
		return
	experience += amount
	while experience >= get_exp_to_next_level() and level < Constants.MAX_PET_LEVEL:
		experience -= get_exp_to_next_level()
		level += 1
		level_changed.emit(level)


## スキルを習得
func learn_skill(skill: SkillData) -> bool:
	for s in learned_skills:
		if s.skill_name == skill.skill_name:
			return false
	learned_skills.append(skill)
	skill_learned.emit(skill)
	return true


## スキルを装備（最大スロット数チェック）
func equip_skill(skill: SkillData) -> bool:
	if equipped_skills.size() >= Constants.MAX_SKILL_SLOTS:
		return false
	for s in equipped_skills:
		if s.skill_name == skill.skill_name:
			return false
	equipped_skills.append(skill)
	return true


## スキルを装備解除
func unequip_skill(skill: SkillData) -> void:
	for i in range(equipped_skills.size()):
		if equipped_skills[i].skill_name == skill.skill_name:
			equipped_skills.remove_at(i)
			return


## タイプ別の成長倍率
func _growth_rate(stat: String) -> int:
	match pet_type:
		Enums.PetType.RUNNER:
			# 素早さ重視
			match stat:
				"hp": return 8
				"attack": return 3
				"defense": return 2
				"speed": return 5
		Enums.PetType.WALKER:
			# バランス型、HP・防御寄り
			match stat:
				"hp": return 10
				"attack": return 3
				"defense": return 4
				"speed": return 3
		Enums.PetType.SPRINTER:
			# 攻撃重視
			match stat:
				"hp": return 6
				"attack": return 5
				"defense": return 2
				"speed": return 4
	return 3

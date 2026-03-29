class_name SkillDatabase
extends RefCounted

## スキルのマスタデータ管理
## 全スキル定義をコード内で保持し、条件に応じて返す

static func get_all_skills() -> Array[SkillData]:
	return [
		# --- 共通攻撃スキル ---
		_create_attack("タックル", "体当たりで攻撃する", 40, 100, 1),
		_create_attack("パワーストライク", "力を込めた一撃", 60, 90, 5),
		_create_attack("メガインパクト", "全力の一撃。威力は高いが命中が低い", 90, 75, 15),

		# --- Runner 専用 ---
		_create_attack_typed("クイックダッシュ", "素早い突進攻撃", 50, 95, 3, Enums.PetType.RUNNER),
		_create_buff_typed("アクセラレーション", "素早さを上げる", Enums.PetStat.SPEED, 0.3, 3, 8, Enums.PetType.RUNNER),

		# --- Walker 専用 ---
		_create_attack_typed("ステディプレス", "じわじわと押し込む攻撃", 45, 100, 3, Enums.PetType.WALKER),
		_create_buff_typed("アイアンガード", "防御を上げる", Enums.PetStat.DEFENSE, 0.3, 3, 8, Enums.PetType.WALKER),
		_create_heal_typed("リカバリーウォーク", "HPを回復する", 40, 10, Enums.PetType.WALKER),

		# --- Sprinter 専用 ---
		_create_attack_typed("バーストアタック", "爆発的な攻撃", 70, 85, 3, Enums.PetType.SPRINTER),
		_create_buff_typed("フルチャージ", "攻撃力を上げる", Enums.PetStat.ATTACK, 0.3, 3, 8, Enums.PetType.SPRINTER),

		# --- 共通デバフスキル ---
		_create_debuff("スロウダウン", "相手の素早さを下げる", Enums.PetStat.SPEED, -0.2, 3, 12),
		_create_debuff("アーマーブレイク", "相手の防御を下げる", Enums.PetStat.DEFENSE, -0.2, 3, 12),
	]


## 初期スキルを取得（タイプ別 + 共通のタックル）
static func get_starter_skills(pet_type: Enums.PetType) -> Array[SkillData]:
	var starters: Array[SkillData] = []
	for skill in get_all_skills():
		if skill.required_level <= 1:
			if skill.any_type or skill.required_type == pet_type:
				starters.append(skill)
	return starters


## 指定レベルで習得可能なスキルを取得
static func get_learnable_skills(pet_type: Enums.PetType, level: int) -> Array[SkillData]:
	var result: Array[SkillData] = []
	for skill in get_all_skills():
		if skill.required_level == level:
			if skill.any_type or skill.required_type == pet_type:
				result.append(skill)
	return result


# --- ヘルパー ---

static func _create_attack(sname: String, desc: String, power: int, accuracy: int, req_level: int) -> SkillData:
	var s := SkillData.new()
	s.skill_name = sname
	s.description = desc
	s.skill_type = SkillData.SkillType.ATTACK
	s.target_type = SkillData.TargetType.ENEMY
	s.power = power
	s.accuracy = accuracy
	s.required_level = req_level
	s.any_type = true
	return s


static func _create_attack_typed(sname: String, desc: String, power: int, accuracy: int, req_level: int, ptype: Enums.PetType) -> SkillData:
	var s := _create_attack(sname, desc, power, accuracy, req_level)
	s.any_type = false
	s.required_type = ptype
	return s


static func _create_buff_typed(sname: String, desc: String, stat: Enums.PetStat, modifier: float, duration: int, req_level: int, ptype: Enums.PetType) -> SkillData:
	var s := SkillData.new()
	s.skill_name = sname
	s.description = desc
	s.skill_type = SkillData.SkillType.BUFF
	s.target_type = SkillData.TargetType.SELF
	s.stat_target = stat
	s.stat_modifier = modifier
	s.duration_turns = duration
	s.required_level = req_level
	s.any_type = false
	s.required_type = ptype
	return s


static func _create_heal_typed(sname: String, desc: String, power: int, req_level: int, ptype: Enums.PetType) -> SkillData:
	var s := SkillData.new()
	s.skill_name = sname
	s.description = desc
	s.skill_type = SkillData.SkillType.HEAL
	s.target_type = SkillData.TargetType.SELF
	s.power = power
	s.accuracy = 100
	s.required_level = req_level
	s.any_type = false
	s.required_type = ptype
	return s


static func _create_debuff(sname: String, desc: String, stat: Enums.PetStat, modifier: float, duration: int, req_level: int) -> SkillData:
	var s := SkillData.new()
	s.skill_name = sname
	s.description = desc
	s.skill_type = SkillData.SkillType.DEBUFF
	s.target_type = SkillData.TargetType.ENEMY
	s.stat_target = stat
	s.stat_modifier = modifier
	s.duration_turns = duration
	s.required_level = req_level
	s.any_type = true
	return s

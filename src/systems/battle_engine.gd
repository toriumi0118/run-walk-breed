class_name BattleEngine
extends RefCounted

## 1v1 オートバトルエンジン（ターン制）
## バトル中はプレイヤー操作なし。AIがスキルを自動選択して行動する。

signal turn_started(turn: int, attacker_name: String)
signal skill_used(user_name: String, skill: SkillData, damage: int)
signal hp_changed(pet_name: String, current_hp: int, max_hp: int)
signal buff_applied(pet_name: String, skill: SkillData)
signal battle_ended(result: Enums.BattleResult, winner_name: String)

var _pet_a: PetData
var _pet_b: PetData

# バトル中の動的ステート
var _hp_a: int
var _hp_b: int
var _max_hp_a: int
var _max_hp_b: int
var _buffs_a: Array[Dictionary] = []  # [{"stat", "modifier", "remaining_turns"}]
var _buffs_b: Array[Dictionary] = []
var _current_turn: int = 0
var _log: Array[String] = []


func setup(pet_a: PetData, pet_b: PetData) -> void:
	_pet_a = pet_a
	_pet_b = pet_b
	_max_hp_a = pet_a.get_max_hp()
	_max_hp_b = pet_b.get_max_hp()
	_hp_a = _max_hp_a
	_hp_b = _max_hp_b
	_buffs_a.clear()
	_buffs_b.clear()
	_current_turn = 0
	_log.clear()


## バトル全体を実行し、結果を返す
func run_battle() -> Dictionary:
	var result := {
		"result": Enums.BattleResult.DRAW,
		"winner": "",
		"turns": 0,
		"log": _log,
	}

	while _current_turn < Constants.MAX_BATTLE_TURNS:
		_current_turn += 1

		# 素早さで先攻/後攻を決定
		var speed_a := _get_effective_stat(_pet_a, Enums.PetStat.SPEED, _buffs_a)
		var speed_b := _get_effective_stat(_pet_b, Enums.PetStat.SPEED, _buffs_b)
		var a_first := speed_a >= speed_b

		var first: PetData = _pet_a if a_first else _pet_b
		var second: PetData = _pet_b if a_first else _pet_a

		# 先攻の行動
		turn_started.emit(_current_turn, first.pet_name)
		_execute_turn(first, second, a_first)
		if _check_battle_end(result):
			break

		# 後攻の行動
		_execute_turn(second, first, not a_first)
		if _check_battle_end(result):
			break

		# バフのターン経過処理
		_tick_buffs(_buffs_a)
		_tick_buffs(_buffs_b)

	result["turns"] = _current_turn

	# ターン上限に達した場合、残HP割合で判定
	if result["result"] == Enums.BattleResult.DRAW and _current_turn >= Constants.MAX_BATTLE_TURNS:
		var ratio_a := float(_hp_a) / float(_max_hp_a)
		var ratio_b := float(_hp_b) / float(_max_hp_b)
		if ratio_a > ratio_b:
			result["result"] = Enums.BattleResult.WIN
			result["winner"] = _pet_a.pet_name
		elif ratio_b > ratio_a:
			result["result"] = Enums.BattleResult.LOSE
			result["winner"] = _pet_b.pet_name
		else:
			result["result"] = Enums.BattleResult.DRAW
		battle_ended.emit(result["result"], result["winner"])

	result["log"] = _log
	return result


func get_hp_a() -> int:
	return _hp_a


func get_hp_b() -> int:
	return _hp_b


func get_max_hp_a() -> int:
	return _max_hp_a


func get_max_hp_b() -> int:
	return _max_hp_b


func get_current_turn() -> int:
	return _current_turn


## 1ターン分の行動を実行
func _execute_turn(attacker: PetData, defender: PetData, attacker_is_a: bool) -> void:
	var attacker_buffs: Array[Dictionary] = _buffs_a if attacker_is_a else _buffs_b
	var defender_buffs: Array[Dictionary] = _buffs_b if attacker_is_a else _buffs_a

	var skill := _select_skill(attacker, defender, attacker_is_a)
	if not skill:
		_add_log("%s は何もしなかった" % attacker.pet_name)
		return

	match skill.skill_type:
		SkillData.SkillType.ATTACK:
			_execute_attack(attacker, defender, skill, attacker_is_a, attacker_buffs, defender_buffs)
		SkillData.SkillType.BUFF:
			_execute_buff(attacker, skill, attacker_buffs)
		SkillData.SkillType.DEBUFF:
			_execute_debuff(attacker, defender, skill, defender_buffs)
		SkillData.SkillType.HEAL:
			_execute_heal(attacker, skill, attacker_is_a)


func _execute_attack(attacker: PetData, defender: PetData, skill: SkillData,
		attacker_is_a: bool, atk_buffs: Array[Dictionary], def_buffs: Array[Dictionary]) -> void:
	# 命中判定
	if randi() % 100 >= skill.accuracy:
		_add_log("%s の %s は外れた！" % [attacker.pet_name, skill.skill_name])
		skill_used.emit(attacker.pet_name, skill, 0)
		return

	var atk := _get_effective_stat(attacker, Enums.PetStat.ATTACK, atk_buffs)
	var def := _get_effective_stat(defender, Enums.PetStat.DEFENSE, def_buffs)

	# ダメージ計算: (スキル威力 * 攻撃 / 防御) にランダム補正
	var base_damage := float(skill.power * atk) / float(maxi(def, 1))
	var random_factor := randf_range(0.85, 1.15)
	var damage := maxi(1, int(base_damage * random_factor))

	if attacker_is_a:
		_hp_b = maxi(0, _hp_b - damage)
		hp_changed.emit(defender.pet_name, _hp_b, _max_hp_b)
	else:
		_hp_a = maxi(0, _hp_a - damage)
		hp_changed.emit(defender.pet_name, _hp_a, _max_hp_a)

	_add_log("%s の %s → %s に %d ダメージ" % [attacker.pet_name, skill.skill_name, defender.pet_name, damage])
	skill_used.emit(attacker.pet_name, skill, damage)


func _execute_buff(attacker: PetData, skill: SkillData, buffs: Array[Dictionary]) -> void:
	buffs.append({
		"stat": skill.stat_target,
		"modifier": skill.stat_modifier,
		"remaining_turns": skill.duration_turns,
	})
	_add_log("%s は %s を使った！" % [attacker.pet_name, skill.skill_name])
	buff_applied.emit(attacker.pet_name, skill)


func _execute_debuff(attacker: PetData, defender: PetData, skill: SkillData,
		defender_buffs: Array[Dictionary]) -> void:
	# 命中判定
	if randi() % 100 >= skill.accuracy:
		_add_log("%s の %s は外れた！" % [attacker.pet_name, skill.skill_name])
		return

	defender_buffs.append({
		"stat": skill.stat_target,
		"modifier": skill.stat_modifier,
		"remaining_turns": skill.duration_turns,
	})
	_add_log("%s は %s で %s を弱体化！" % [attacker.pet_name, skill.skill_name, defender.pet_name])
	buff_applied.emit(defender.pet_name, skill)


func _execute_heal(attacker: PetData, skill: SkillData, attacker_is_a: bool) -> void:
	var heal_amount := skill.power
	if attacker_is_a:
		var old_hp := _hp_a
		_hp_a = mini(_hp_a + heal_amount, _max_hp_a)
		heal_amount = _hp_a - old_hp
		hp_changed.emit(attacker.pet_name, _hp_a, _max_hp_a)
	else:
		var old_hp := _hp_b
		_hp_b = mini(_hp_b + heal_amount, _max_hp_b)
		heal_amount = _hp_b - old_hp
		hp_changed.emit(attacker.pet_name, _hp_b, _max_hp_b)

	_add_log("%s は %s で HP を %d 回復" % [attacker.pet_name, skill.skill_name, heal_amount])
	skill_used.emit(attacker.pet_name, skill, -heal_amount)


## AI: スキルを自動選択
func _select_skill(attacker: PetData, defender: PetData, attacker_is_a: bool) -> SkillData:
	var skills := attacker.equipped_skills
	if skills.is_empty():
		return null

	var hp := _hp_a if attacker_is_a else _hp_b
	var max_hp := _max_hp_a if attacker_is_a else _max_hp_b
	var hp_ratio := float(hp) / float(maxi(max_hp, 1))

	# HP が低い場合、回復スキルを優先
	if hp_ratio < 0.3:
		for skill in skills:
			if skill.skill_type == SkillData.SkillType.HEAL:
				return skill

	# バフが未適用なら、バフスキルを使う（最初の数ターンで）
	var buffs: Array[Dictionary] = _buffs_a if attacker_is_a else _buffs_b
	if buffs.is_empty() and _current_turn <= 3:
		for skill in skills:
			if skill.skill_type == SkillData.SkillType.BUFF:
				return skill

	# デバフ（序盤で 1 回使う）
	if _current_turn <= 2:
		for skill in skills:
			if skill.skill_type == SkillData.SkillType.DEBUFF:
				return skill

	# それ以外は最も威力の高い攻撃スキルを選択
	var best_attack: SkillData = null
	for skill in skills:
		if skill.skill_type == SkillData.SkillType.ATTACK:
			if not best_attack or skill.power > best_attack.power:
				best_attack = skill

	if best_attack:
		return best_attack

	# フォールバック: ランダム
	return skills[randi() % skills.size()]


## バフ/デバフのステータス補正を適用した実効値
func _get_effective_stat(pet: PetData, stat: Enums.PetStat, buffs: Array[Dictionary]) -> int:
	var base_value: int
	match stat:
		Enums.PetStat.HP:
			base_value = pet.get_max_hp()
		Enums.PetStat.ATTACK:
			base_value = pet.get_attack()
		Enums.PetStat.DEFENSE:
			base_value = pet.get_defense()
		Enums.PetStat.SPEED:
			base_value = pet.get_speed()
		_:
			base_value = 0

	var total_modifier := 0.0
	for buff in buffs:
		if buff["stat"] == stat:
			total_modifier += buff["modifier"]

	return maxi(1, int(base_value * (1.0 + total_modifier)))


## バフのターン数を減らし、期限切れを除去
func _tick_buffs(buffs: Array[Dictionary]) -> void:
	var i := buffs.size() - 1
	while i >= 0:
		buffs[i]["remaining_turns"] -= 1
		if buffs[i]["remaining_turns"] <= 0:
			buffs.remove_at(i)
		i -= 1


## バトル終了判定
func _check_battle_end(result: Dictionary) -> bool:
	if _hp_a <= 0:
		result["result"] = Enums.BattleResult.LOSE
		result["winner"] = _pet_b.pet_name
		battle_ended.emit(Enums.BattleResult.LOSE, _pet_b.pet_name)
		return true
	if _hp_b <= 0:
		result["result"] = Enums.BattleResult.WIN
		result["winner"] = _pet_a.pet_name
		battle_ended.emit(Enums.BattleResult.WIN, _pet_a.pet_name)
		return true
	return false


func _add_log(message: String) -> void:
	_log.append("[Turn %d] %s" % [_current_turn, message])

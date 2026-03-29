extends Resource
class_name SkillData

## スキルの定義データ

enum SkillType {
	ATTACK,
	BUFF,
	DEBUFF,
	HEAL,
}

enum TargetType {
	ENEMY,
	SELF,
}

@export var skill_name: String = ""
@export var description: String = ""
@export var skill_type: SkillType = SkillType.ATTACK
@export var target_type: TargetType = TargetType.ENEMY

# 戦闘パラメータ
@export var power: int = 0          # 威力（ダメージ / 回復量のベース）
@export var accuracy: int = 100     # 命中率（0-100）
@export var cost: int = 0           # 消費コスト（将来的に SP 等）

# バフ/デバフ用
@export var stat_target: Enums.PetStat = Enums.PetStat.ATTACK
@export var stat_modifier: float = 0.0  # 倍率変化（例: 0.2 = +20%）
@export var duration_turns: int = 0     # 持続ターン数

# 習得条件
@export var required_level: int = 1
@export var required_type: Enums.PetType = Enums.PetType.RUNNER
@export var any_type: bool = true  # true なら全タイプが習得可能

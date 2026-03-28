class_name Enums
extends RefCounted

## ゲーム全体で使用する列挙型

enum PetType {
	RUNNER,
	WALKER,
	SPRINTER,
}

enum PetStat {
	HP,
	ATTACK,
	DEFENSE,
	SPEED,
}

enum BattleResult {
	WIN,
	LOSE,
	DRAW,
	TIMEOUT,
}

enum ActivityType {
	WALKING,
	RUNNING,
	IDLE,
}

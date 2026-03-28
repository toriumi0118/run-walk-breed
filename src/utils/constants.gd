class_name Constants
extends RefCounted

## ゲーム全体で使用する定数

# ペット育成
const STEPS_PER_LEVEL_UP: int = 1000
const MAX_PET_LEVEL: int = 100
const BASE_PET_STATS: Dictionary = {
	"hp": 100,
	"attack": 10,
	"defense": 10,
	"speed": 10,
}

# GPS
const MIN_DISTANCE_UPDATE_M: float = 5.0
const EARTH_RADIUS_M: float = 6371000.0

# バトル
const MAX_BATTLE_TURNS: int = 30
const BATTLE_TURN_DURATION_SEC: float = 2.0

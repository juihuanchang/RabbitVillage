class_name CafeActivityData
extends ActivityData

@export var cafe_experience_change := 0
@export var social_experience_change := 0
@export var coin_reward := 0
var resident_id: String:
	get: return participant_resident_id
	set(value): participant_resident_id = value

static func create(id: String, name: String, seconds: float, energy: int, mood: int, cafe_exp: int, social_exp: int = 0, coins: int = 0) -> CafeActivityData:
	var value := CafeActivityData.new()
	value.activity_id = id; value.location_id = "cafe"; value.location_name = "Café"; value.display_name = name
	value.duration_seconds = seconds; value.energy_change = energy; value.mood_change = mood
	value.required_energy = maxi(0, -energy); value.cafe_experience_change = cafe_exp
	value.social_experience_change = social_exp; value.coin_reward = coins
	return value

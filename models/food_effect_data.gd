class_name FoodEffectData
extends Resource

var item_id := ""
var hunger_change := 0
var energy_change := 0
var mood_change := 0

static func create(id: String, hunger := 0, energy := 0, mood := 0) -> FoodEffectData:
	var effect := FoodEffectData.new(); effect.item_id = id; effect.hunger_change = hunger
	effect.energy_change = energy; effect.mood_change = mood; return effect

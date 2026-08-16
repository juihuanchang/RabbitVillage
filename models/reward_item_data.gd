class_name RewardItemData
extends Resource

var item_id := ""
var min_amount := 1
var max_amount := 1
var drop_chance := 1.0

static func create(id: String, chance: float, minimum := 1, maximum := 1) -> RewardItemData:
	var item := RewardItemData.new(); item.item_id = id; item.drop_chance = clampf(chance, 0.0, 1.0)
	item.min_amount = maxi(0, minimum); item.max_amount = maxi(item.min_amount, maximum); return item

func roll_amount() -> int:
	return randi_range(min_amount, max_amount) if randf() <= drop_chance else 0

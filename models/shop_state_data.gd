class_name ShopStateData
extends Resource

var day_key := ""
var daily_offers: Array[Dictionary] = []
var daily_purchase_amounts: Dictionary = {}
var applied_purchase_ids: Array[String] = []
var unlocked_product_ids: Array[String] = []
var total_purchase_count := 0
var total_spent := 0
var visited_day_keys: Array[String] = []

func to_dict() -> Dictionary:
	return {"day_key": day_key, "daily_offers": daily_offers.duplicate(true),
		"daily_purchase_amounts": daily_purchase_amounts.duplicate(true),
		"applied_purchase_ids": applied_purchase_ids.duplicate(), "unlocked_product_ids": unlocked_product_ids.duplicate(),
		"total_purchase_count": total_purchase_count, "total_spent": total_spent, "visited_day_keys": visited_day_keys.duplicate()}

static func from_dict(data: Dictionary) -> ShopStateData:
	var state := ShopStateData.new(); state.day_key = str(data.get("day_key", ""))
	for value: Variant in data.get("daily_offers", []):
		if value is Dictionary: state.daily_offers.append(value.duplicate(true))
	if data.get("daily_purchase_amounts", {}) is Dictionary: state.daily_purchase_amounts = data.get("daily_purchase_amounts", {}).duplicate(true)
	for id: Variant in data.get("applied_purchase_ids", []): state.applied_purchase_ids.append(str(id))
	for id: Variant in data.get("unlocked_product_ids", []): state.unlocked_product_ids.append(str(id))
	state.total_purchase_count = maxi(0, int(data.get("total_purchase_count", 0)))
	state.total_spent = maxi(0, int(data.get("total_spent", 0)))
	for key: Variant in data.get("visited_day_keys", []): state.visited_day_keys.append(str(key))
	return state

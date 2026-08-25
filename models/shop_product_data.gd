class_name ShopProductData
extends Resource

const LOCKED := "locked"
const UNLOCKED := "unlocked"

var product_id := ""
var item_id := ""
var display_name := ""
var base_price := 0
var price_modifier := 1.0
var daily_purchase_limit := 3
var unlock_state := LOCKED
var unlock_condition := ProductUnlockConditionData.new()
var unlocked_at := 0.0

func get_final_unit_price() -> int: return maxi(0, ceili(base_price * price_modifier))
func to_dict() -> Dictionary:
	return {"product_id": product_id, "item_id": item_id, "display_name": display_name,
		"base_price": base_price, "price_modifier": price_modifier, "daily_purchase_limit": daily_purchase_limit,
		"unlock_state": unlock_state, "unlock_condition": unlock_condition.to_dict(), "unlocked_at": unlocked_at}

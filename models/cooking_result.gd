class_name CookingResult
extends Resource

var cooking_record_id := ""
var recipe_id := ""
var result_item_id := ""
var result_amount := 0
var cooked_at := 0.0
var is_first_discovery := false
var success := false
var reason := ""

func to_dict() -> Dictionary:
	return {"cooking_record_id": cooking_record_id, "recipe_id": recipe_id, "result_item_id": result_item_id,
		"result_amount": result_amount, "cooked_at": cooked_at, "is_first_discovery": is_first_discovery,
		"success": success, "reason": reason}

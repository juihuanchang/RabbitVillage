class_name PurchaseResult
extends Resource

var purchase_record_id := ""
var product_id := ""
var item_id := ""
var quantity := 0
var unit_price := 0
var total_price := 0
var purchased_at := 0.0
var success := false
var reason := ""

func to_dict() -> Dictionary:
	return {"purchase_record_id": purchase_record_id, "product_id": product_id, "item_id": item_id,
		"quantity": quantity, "unit_price": unit_price, "total_price": total_price,
		"purchased_at": purchased_at, "success": success, "reason": reason}

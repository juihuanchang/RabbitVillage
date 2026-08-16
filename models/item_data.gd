class_name ItemData
extends Resource

var item_id := ""
var display_name := ""
var category := ""
var description := ""
var max_stack := 99
var is_consumable := false

static func create(id: String, name: String, item_category: String, consumable := false) -> ItemData:
	var item := ItemData.new(); item.item_id = id; item.display_name = name
	item.category = item_category; item.is_consumable = consumable; return item

func to_dict() -> Dictionary:
	return {"item_id": item_id, "display_name": display_name, "category": category,
		"description": description, "max_stack": max_stack, "is_consumable": is_consumable}

class_name InventoryManager
extends Node

signal inventory_changed(item_id: String, old_amount: int, new_amount: int, source_type: String, source_id: String)
signal item_discovered(item_id: String, source_type: String, source_id: String, discovered_at: float)

var _item_data: Dictionary = {}
var _entries: Dictionary = {}

func _init() -> void:
	_register_item(ItemData.create("carrot", "Carrot", "food", true))
	_register_item(ItemData.create("leaf", "Leaf", "material"))
	_register_item(ItemData.create("twig", "Twig", "material"))
	_register_item(ItemData.create("small_stone", "Small Stone", "material"))
	_register_item(ItemData.create("driftwood", "Driftwood", "material"))
	_register_item(ItemData.create("apple", "Apple", "food", true))
	_register_item(ItemData.create("bread", "Bread", "food", true))
	_register_item(ItemData.create("berry_juice", "Berry Juice", "food", true))
	_register_item(ItemData.create("small_snack", "Small Snack", "food", true))
	_register_item(ItemData.create("carrot_sandwich", "Carrot Sandwich", "cooked_food", true))
	_register_item(ItemData.create("forest_salad", "Forest Salad", "cooked_food", true))
	_register_item(ItemData.create("berry_toast", "Berry Toast", "cooked_food", true))
	_register_item(ItemData.create("picnic_snack", "Picnic Snack", "cooked_food", true))

func setup(saved_entries: Dictionary = {}) -> void:
	for item_id: String in saved_entries:
		if _entries.has(item_id) and saved_entries[item_id] is Dictionary:
			var entry := InventoryEntry.from_dict(saved_entries[item_id])
			entry.item_id = item_id; _entries[item_id] = entry

func _register_item(item: ItemData) -> void:
	_item_data[item.item_id] = item
	var entry := InventoryEntry.new(); entry.item_id = item.item_id; _entries[item.item_id] = entry

func get_item_amount(item_id: String) -> int:
	var entry := _entries.get(item_id) as InventoryEntry
	return entry.amount if entry != null else 0

func get_total_obtained(item_id: String) -> int:
	var entry := _entries.get(item_id) as InventoryEntry
	return entry.total_obtained if entry != null else 0

func has_item(item_id: String, amount: int = 1) -> bool:
	return amount >= 0 and get_item_amount(item_id) >= amount

func add_item(item_id: String, amount: int, source_type: String, source_id: String) -> bool:
	var entry := _entries.get(item_id) as InventoryEntry
	if entry == null or amount <= 0: return false
	var old_amount := entry.amount; var is_first_obtain := entry.total_obtained == 0
	var obtained_at := TimeManager.get_now(); entry.amount += amount; entry.total_obtained += amount
	entry.last_obtained_at = obtained_at
	if is_first_obtain: entry.first_obtained_at = obtained_at
	inventory_changed.emit(item_id, old_amount, entry.amount, source_type, source_id)
	if is_first_obtain: item_discovered.emit(item_id, source_type, source_id, obtained_at)
	return true

func remove_item(item_id: String, amount: int, source_type: String, source_id: String) -> bool:
	var entry := _entries.get(item_id) as InventoryEntry
	if entry == null or amount <= 0 or entry.amount < amount: return false
	var old_amount := entry.amount; entry.amount -= amount
	inventory_changed.emit(item_id, old_amount, entry.amount, source_type, source_id); return true

## Transaction rollback only restores current amount; it must not increase total_obtained.
func rollback_removed_item(item_id: String, amount: int, source_type: String, source_id: String) -> bool:
	var entry := _entries.get(item_id) as InventoryEntry
	if entry == null or amount <= 0: return false
	var old_amount := entry.amount; entry.amount += amount
	inventory_changed.emit(item_id, old_amount, entry.amount, source_type, source_id); return true

func get_items_by_category(category: String) -> Array[InventoryEntry]:
	var result: Array[InventoryEntry] = []
	for item_id: String in _entries:
		var item := _item_data[item_id] as ItemData
		if item.category == category: result.append(_entries[item_id])
	return result

func get_all_items() -> Array[InventoryEntry]:
	var result: Array[InventoryEntry] = []; result.assign(_entries.values()); return result

func is_item_discovered(item_id: String) -> bool: return get_total_obtained(item_id) > 0

func to_dict() -> Dictionary:
	var result := {}
	for item_id: String in _entries: result[item_id] = (_entries[item_id] as InventoryEntry).to_dict()
	return result

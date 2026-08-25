class_name CookingManager
extends Node

signal cooking_completed(result: CookingResult)
signal recipe_discovered(recipe: RecipeData)
signal recipe_unlocked(recipe: RecipeData)

var _inventory: InventoryManager
var _recipes: Dictionary = {}
var _discovered_recipe_ids: Array[String] = []
var _unlocked_recipe_ids: Array[String] = []
var _applied_cooking_ids: Array[String] = []
var _transactions: Dictionary = {}

func _init() -> void:
	_register(RecipeData.create("carrot_sandwich", "胡蘿蔔三明治", "carrot_sandwich", [RecipeIngredientData.create("carrot"), RecipeIngredientData.create("bread")]))
	_register(RecipeData.create("forest_salad", "森林沙拉", "forest_salad", [RecipeIngredientData.create("leaf", 2), RecipeIngredientData.create("apple")]))
	_register(RecipeData.create("berry_toast", "莓果吐司", "berry_toast", [RecipeIngredientData.create("bread"), RecipeIngredientData.create("berry_juice")]))
	_register(RecipeData.create("picnic_snack", "野餐小點", "picnic_snack", [RecipeIngredientData.create("small_snack"), RecipeIngredientData.create("apple")]))

func _register(recipe: RecipeData) -> void: _recipes[recipe.recipe_id] = recipe

func setup(inventory: InventoryManager, saved_state: Dictionary = {}) -> void:
	_inventory = inventory
	for id: Variant in saved_state.get("discovered_recipe_ids", []): _discovered_recipe_ids.append(str(id))
	for id: Variant in saved_state.get("unlocked_recipe_ids", []): _unlocked_recipe_ids.append(str(id))
	for id: Variant in saved_state.get("applied_cooking_ids", []): _applied_cooking_ids.append(str(id))
	for recipe: RecipeData in _recipes.values(): recipe.is_unlocked = _unlocked_recipe_ids.has(recipe.recipe_id)
	refresh_recipe_unlocks()

func get_recipes() -> Array[RecipeData]:
	var result: Array[RecipeData] = []; result.assign(_recipes.values()); return result
func get_unlocked_recipes() -> Array[RecipeData]:
	var result: Array[RecipeData] = []
	for recipe: RecipeData in _recipes.values():
		if recipe.is_unlocked: result.append(recipe)
	return result
func get_recipe(recipe_id: String) -> RecipeData: return _recipes.get(recipe_id) as RecipeData

func refresh_recipe_unlocks() -> void:
	if _inventory == null: return
	for recipe: RecipeData in _recipes.values():
		if recipe.is_unlocked: continue
		var can_unlock := true
		for ingredient: RecipeIngredientData in recipe.ingredients:
			if not _inventory.is_item_discovered(ingredient.item_id): can_unlock = false; break
		if can_unlock:
			recipe.is_unlocked = true; recipe.unlocked_at = TimeManager.get_now()
			if not _unlocked_recipe_ids.has(recipe.recipe_id): _unlocked_recipe_ids.append(recipe.recipe_id)
			recipe_unlocked.emit(recipe)

func can_cook(recipe_id: String) -> Dictionary:
	refresh_recipe_unlocks(); var recipe := get_recipe(recipe_id)
	if recipe == null: return {"success": false, "reason": "invalid_recipe"}
	if not recipe.is_unlocked: return {"success": false, "reason": "recipe_locked"}
	for ingredient: RecipeIngredientData in recipe.ingredients:
		if not _inventory.has_item(ingredient.item_id, ingredient.required_amount):
			return {"success": false, "reason": "missing_ingredient", "item_id": ingredient.item_id}
	return {"success": true, "reason": ""}

func cook(recipe_id: String, cooking_record_id := "") -> CookingResult:
	var result := CookingResult.new(); result.recipe_id = recipe_id
	result.cooking_record_id = cooking_record_id if not cooking_record_id.is_empty() else _make_id()
	if _applied_cooking_ids.has(result.cooking_record_id) or _transactions.has(result.cooking_record_id):
		result.reason = "duplicate_cooking"; return result
	var check := can_cook(recipe_id)
	if not bool(check.success): result.reason = str(check.reason); return result
	var recipe := get_recipe(recipe_id); result.result_item_id = recipe.result_item_id
	result.result_amount = recipe.result_amount; result.cooked_at = TimeManager.get_now(); _transactions[result.cooking_record_id] = true
	var removed: Array[RecipeIngredientData] = []
	for ingredient: RecipeIngredientData in recipe.ingredients:
		if not _inventory.remove_item(ingredient.item_id, ingredient.required_amount, "cooking", result.cooking_record_id):
			_rollback_ingredients(removed, result.cooking_record_id); _transactions.erase(result.cooking_record_id)
			result.reason = "ingredient_remove_failed"; return result
		removed.append(ingredient)
	if not _inventory.add_item(recipe.result_item_id, recipe.result_amount, "cooking", result.cooking_record_id):
		_rollback_ingredients(removed, result.cooking_record_id); _transactions.erase(result.cooking_record_id)
		result.reason = "result_add_failed"; return result
	result.is_first_discovery = not _discovered_recipe_ids.has(recipe_id)
	if result.is_first_discovery: _discovered_recipe_ids.append(recipe_id); recipe_discovered.emit(recipe)
	_applied_cooking_ids.append(result.cooking_record_id); _transactions.erase(result.cooking_record_id)
	result.success = true; cooking_completed.emit(result); return result

func _rollback_ingredients(removed: Array[RecipeIngredientData], record_id: String) -> void:
	for ingredient: RecipeIngredientData in removed:
		_inventory.rollback_removed_item(ingredient.item_id, ingredient.required_amount, "cooking_rollback", record_id)
func is_recipe_discovered(recipe_id: String) -> bool: return _discovered_recipe_ids.has(recipe_id)
func get_discovered_recipe_count() -> int: return _discovered_recipe_ids.size()
func _make_id() -> String: return "cooking_%d_%d" % [int(TimeManager.get_now() * 1000000.0), randi_range(1000, 9999)]
func to_dict() -> Dictionary:
	return {"discovered_recipe_ids": _discovered_recipe_ids.duplicate(), "unlocked_recipe_ids": _unlocked_recipe_ids.duplicate(), "applied_cooking_ids": _applied_cooking_ids.duplicate()}

class_name RecipeData
extends Resource

var recipe_id := ""
var display_name := ""
var ingredients: Array[RecipeIngredientData] = []
var result_item_id := ""
var result_amount := 1
var unlock_condition := ProductUnlockConditionData.new()
var is_unlocked := false
var unlocked_at := 0.0

static func create(id: String, name: String, result_id: String, ingredient_list: Array) -> RecipeData:
	var recipe := RecipeData.new(); recipe.recipe_id = id; recipe.display_name = name; recipe.result_item_id = result_id
	recipe.ingredients.assign(ingredient_list); return recipe

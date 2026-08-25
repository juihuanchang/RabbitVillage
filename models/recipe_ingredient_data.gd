class_name RecipeIngredientData
extends Resource

var item_id := ""
var required_amount := 1

static func create(id: String, amount := 1) -> RecipeIngredientData:
	var ingredient := RecipeIngredientData.new(); ingredient.item_id = id; ingredient.required_amount = maxi(1, amount); return ingredient

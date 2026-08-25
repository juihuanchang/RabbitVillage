class_name ProductUnlockConditionData
extends Resource

var condition_type := "always"
var target_id := ""
var required_value := 0

static func create(type: String, target := "", value := 0) -> ProductUnlockConditionData:
	var condition := ProductUnlockConditionData.new()
	condition.condition_type = type; condition.target_id = target; condition.required_value = value
	return condition

func to_dict() -> Dictionary:
	return {"condition_type": condition_type, "target_id": target_id, "required_value": required_value}

static func from_dict(data: Dictionary) -> ProductUnlockConditionData:
	return create(str(data.get("condition_type", "always")), str(data.get("target_id", "")), int(data.get("required_value", 0)))

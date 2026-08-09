class_name HarvestResult
extends Resource

@export var harvest_record_id := ""
@export var farm_cycle_id := ""
@export var crop_id := "carrot"
@export var amount := 10
@export var harvested_at := 0.0
@export var village_experience_reward := 0
@export var is_first_harvest := false

func to_dict() -> Dictionary:
    return {"harvest_record_id": harvest_record_id, "farm_cycle_id": farm_cycle_id, "crop_id": crop_id, "amount": amount, "harvested_at": harvested_at, "village_experience_reward": village_experience_reward, "is_first_harvest": is_first_harvest}

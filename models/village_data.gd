class_name VillageData
extends Resource

@export var progress: VillageProgressData = VillageProgressData.new()
@export var conditions: VillageConditionData = VillageConditionData.new()
@export var unlocked_building_ids: Array[String] = ["rest_pavilion"]
@export var completed_village_event_ids: Array[String] = []
@export var pending_village_events: Array[Dictionary] = []
@export var building_records: Dictionary = {}
@export var active_construction: Dictionary = {}
@export var completed_construction_ids: Array[String] = []
@export var building_interactions: Dictionary = {}
@export var active_building_interaction: Dictionary = {}
@export var notices: Array[Dictionary] = []
@export var farm: Dictionary = {}
@export var carrot_amount := 0

func to_dict() -> Dictionary:
	return {"progress": progress.to_dict(), "conditions": conditions.to_dict(),
		"unlocked_building_ids": unlocked_building_ids.duplicate(),
		"completed_village_event_ids": completed_village_event_ids.duplicate(),
		"pending_village_events": pending_village_events.duplicate(true),
		"building_records": building_records.duplicate(true),
		"active_construction": active_construction.duplicate(true),
		"completed_construction_ids": completed_construction_ids.duplicate(),
		"building_interactions": building_interactions.duplicate(true),
		"active_building_interaction": active_building_interaction.duplicate(true),
		"notices": notices.duplicate(true), "farm": farm.duplicate(true),
		"carrot_amount": carrot_amount}

static func from_dict(data: Dictionary) -> VillageData:
	var v := VillageData.new()
	if data.get("progress", {}) is Dictionary: v.progress = VillageProgressData.from_dict(data.get("progress", {}))
	if data.get("conditions", {}) is Dictionary: v.conditions = VillageConditionData.from_dict(data.get("conditions", {}))
	v.unlocked_building_ids.clear()
	for id: Variant in data.get("unlocked_building_ids", ["rest_pavilion"]): v.unlocked_building_ids.append(str(id))
	for id: Variant in data.get("completed_village_event_ids", []): v.completed_village_event_ids.append(str(id))
	for event: Variant in data.get("pending_village_events", []):
		if event is Dictionary: v.pending_village_events.append(event.duplicate(true))
	for id: Variant in data.get("completed_construction_ids", []): v.completed_construction_ids.append(str(id))
	for field in ["building_records", "active_construction", "building_interactions", "active_building_interaction", "farm"]:
		if data.get(field, {}) is Dictionary: v.set(field, data.get(field, {}).duplicate(true))
	for notice: Variant in data.get("notices", []):
		if notice is Dictionary: v.notices.append(notice.duplicate(true))
	v.carrot_amount = maxi(0, int(data.get("carrot_amount", 0)))
	return v

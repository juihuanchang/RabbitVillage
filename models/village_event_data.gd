class_name VillageEventData
extends Resource
@export var event_id := ""
@export var title := ""
@export var description := ""
@export var required_village_level := 1
@export var required_total_activity_count := 0
@export var required_forest_activity_count := 0
@export var required_fishing_activity_count := 0
@export var required_home_activity_count := 0
@export var required_building_id := ""
@export var required_building_use_count := 0
@export var unlock_building_id := ""
@export var triggered_at := 0.0
@export var confirmed_at := 0.0
@export var state := VillageEventState.LOCKED
@export var is_applied := false
func to_dict() -> Dictionary:
	return {"event_id": event_id, "title": title, "description": description,
		"required_village_level": required_village_level, "required_total_activity_count": required_total_activity_count,
		"required_forest_activity_count": required_forest_activity_count,
		"required_fishing_activity_count": required_fishing_activity_count,
		"required_home_activity_count": required_home_activity_count, "required_building_id": required_building_id,
		"required_building_use_count": required_building_use_count, "unlock_building_id": unlock_building_id,
		"triggered_at": triggered_at, "confirmed_at": confirmed_at, "state": state, "is_applied": is_applied}
static func from_dict(d: Dictionary) -> VillageEventData:
	var e := VillageEventData.new()
	for key in ["event_id", "title", "description", "required_building_id", "unlock_building_id", "state"]: e.set(key, str(d.get(key, e.get(key))))
	for key in ["required_village_level", "required_total_activity_count", "required_forest_activity_count", "required_fishing_activity_count", "required_home_activity_count", "required_building_use_count"]: e.set(key, int(d.get(key, e.get(key))))
	e.triggered_at = float(d.get("triggered_at", 0.0)); e.confirmed_at = float(d.get("confirmed_at", 0.0)); e.is_applied = bool(d.get("is_applied", false)); return e

class_name ConstructionRecord
extends Resource
@export var construction_record_id := ""
@export var building_id := ""
@export var slot_id := ""
@export var started_at := 0.0
@export var ends_at := 0.0
@export var completed_at := 0.0
@export var is_completed := false
func to_dict() -> Dictionary:
	return {"construction_record_id": construction_record_id, "building_id": building_id, "slot_id": slot_id,
		"started_at": started_at, "ends_at": ends_at, "completed_at": completed_at, "is_completed": is_completed}
static func from_dict(d: Dictionary) -> ConstructionRecord:
	var r := ConstructionRecord.new(); r.construction_record_id = str(d.get("construction_record_id", ""))
	r.building_id = str(d.get("building_id", "")); r.slot_id = str(d.get("slot_id", ""))
	r.started_at = float(d.get("started_at", 0.0)); r.ends_at = float(d.get("ends_at", 0.0))
	r.completed_at = float(d.get("completed_at", 0.0)); r.is_completed = bool(d.get("is_completed", false)); return r

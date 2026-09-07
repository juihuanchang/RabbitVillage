class_name EndingMemorySnapshot
extends Resource

@export var snapshot_id := ""
@export var ending_id := ""
@export var created_at := 0.0
@export var profile_snapshot_id := ""
@export var profile_snapshot: Dictionary = {}
@export var timeline: Array[Dictionary] = []
@export var important_memories: Array[Dictionary] = []
@export var growth_album_highlights: Array[Dictionary] = []
@export var ending_payload: Dictionary = {}

func to_dict() -> Dictionary:
	return {
		"snapshot_id": snapshot_id,
		"ending_id": ending_id,
		"created_at": created_at,
		"profile_snapshot_id": profile_snapshot_id,
		"profile_snapshot": profile_snapshot.duplicate(true),
		"timeline": timeline.duplicate(true),
		"important_memories": important_memories.duplicate(true),
		"growth_album_highlights": growth_album_highlights.duplicate(true),
		"ending_payload": ending_payload.duplicate(true)
	}

static func from_dict(raw: Dictionary) -> EndingMemorySnapshot:
	var value := EndingMemorySnapshot.new()
	value.snapshot_id = str(raw.get("snapshot_id", ""))
	value.ending_id = str(raw.get("ending_id", ""))
	value.created_at = maxf(0.0, float(raw.get("created_at", 0.0)))
	value.profile_snapshot_id = str(raw.get("profile_snapshot_id", ""))
	if raw.get("profile_snapshot", {}) is Dictionary: value.profile_snapshot = raw.get("profile_snapshot", {}).duplicate(true)
	for item: Variant in raw.get("timeline", []):
		if item is Dictionary: value.timeline.append(item.duplicate(true))
	for item: Variant in raw.get("important_memories", []):
		if item is Dictionary: value.important_memories.append(item.duplicate(true))
	for item: Variant in raw.get("growth_album_highlights", []):
		if item is Dictionary: value.growth_album_highlights.append(item.duplicate(true))
	if raw.get("ending_payload", {}) is Dictionary: value.ending_payload = raw.get("ending_payload", {}).duplicate(true)
	return value

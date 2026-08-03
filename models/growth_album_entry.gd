class_name GrowthAlbumEntry
extends Resource

@export var id: String = ""
@export var growth_mark_id: String = ""
@export var title: String = ""
@export_multiline var description: String = ""
@export var growth_path: String = ""
@export var stage: int = 0
@export var unlocked_at: float = 0.0
@export var journal_id: String = ""
@export var illustration_id: String = ""

func _init(
		initial_id: String = "",
		initial_growth_mark_id: String = "",
		initial_title: String = "",
		initial_description: String = "",
		initial_growth_path: String = "",
		initial_stage: int = 0,
		initial_unlocked_at: float = 0.0,
		initial_journal_id: String = "",
		initial_illustration_id: String = ""
) -> void:
	id = initial_id
	growth_mark_id = initial_growth_mark_id
	title = initial_title
	description = initial_description
	growth_path = initial_growth_path
	stage = initial_stage
	unlocked_at = TimeManager.get_now() if initial_unlocked_at <= 0.0 else initial_unlocked_at
	journal_id = initial_journal_id
	illustration_id = initial_illustration_id

func to_dict() -> Dictionary:
	return {
		"id": id,
		"growth_mark_id": growth_mark_id,
		"title": title,
		"description": description,
		"growth_path": growth_path,
		"stage": stage,
		"unlocked_at": unlocked_at,
		"journal_id": journal_id,
		"illustration_id": illustration_id
	}

static func from_dict(data: Dictionary) -> GrowthAlbumEntry:
	return GrowthAlbumEntry.new(
		str(data.get("id", data.get("Id", ""))),
		str(data.get("growth_mark_id", data.get("GrowthMarkId", ""))),
		str(data.get("title", data.get("Title", ""))),
		str(data.get("description", data.get("Description", ""))),
		str(data.get("growth_path", data.get("GrowthPath", ""))),
		int(data.get("stage", data.get("Stage", 0))),
		float(data.get("unlocked_at", data.get("UnlockedAt", 0.0))),
		str(data.get("journal_id", data.get("JournalId", ""))),
		str(data.get("illustration_id", data.get("IllustrationId", "")))
	)

func is_valid() -> bool:
	return not id.is_empty() and not growth_mark_id.is_empty() and not title.is_empty()

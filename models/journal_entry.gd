class_name JournalEntry
extends Resource

@export var journal_id := ""
@export var journal_type := "activity"
@export var rabbit_name := ""
@export var activity_record_id := ""
@export var date := ""
@export var activity_id := ""
@export var location_id := ""
@export var location_name := ""
@export var created_at := 0.0
@export var title := ""
@export_multiline var content := ""
@export var stat_changes: Dictionary = {}
@export var items: Array[String] = []
@export var growth_mark_id := ""
@export var is_read := false
@export var is_favorite := false
@export var is_special_memory := false
@export var illustration_id := ""

# Week 4 village fields. Kept for backward compatibility.
@export var village_event_id := ""
@export var building_id := ""
@export var construction_record_id := ""
@export var building_use_record_id := ""
@export var notice_id := ""
@export var notice_date := ""
@export var farm_cycle_id := ""
@export var harvest_record_id := ""
@export var village_stage := 0
@export var is_village_memory := false

# Week 5 permanent-life fields.
@export var food_use_record_id := ""
@export var food_id := ""
@export var reward_record_id := ""
@export var item_id := ""
@export var item_discovery_id := ""
@export var life_event_id := ""
@export var growth_path := ""
@export var growth_stage := 0
@export var growth_event_id := ""
@export var is_life_memory := false

# Week 6 shop / cooking / life-location fields.
@export var purchase_record_id := ""
@export var shop_id := ""
@export var product_id := ""
@export var cooking_record_id := ""
@export var recipe_id := ""
@export var life_location_id := ""
@export var life_location_activity_id := ""
@export var shop_event_id := ""
@export var cooking_event_id := ""
@export var picnic_event_id := ""

# Week 7 building / cafe / advanced-growth fields.
# building_id is inherited from Week 4; building_slot_id and construction_id are
# canonical Week 7 aliases kept alongside the legacy construction_record_id field.
@export var building_slot_id := ""
@export var construction_id := ""
@export var cafe_activity_id := ""
@export var village_progress_event_id := ""
@export var growth_form := "none"

# Week 8 final-growth / life-resume / ending fields.
@export var growth_direction_choice_id := ""
@export var final_growth_record_id := ""
@export var final_form := "none"
@export var life_profile_snapshot_id := ""
@export var ending_id := ""
@export var ending_snapshot_id := ""
@export var is_post_ending := false

# Week 9 resident / relationship fields.
@export var resident_id := ""
@export var relationship_state := ""
@export var shared_activity_id := ""
@export var resident_event_id := ""
@export var resident_interaction_id := ""
@export var invitation_id := ""

func _init(
	initial_journal_id := "",
	initial_record_id := "",
	initial_date := "",
	initial_activity_id := "",
	initial_rabbit_name := "",
	initial_title := "",
	initial_content := "",
	initial_created_at := 0.0,
	initial_journal_type := "activity",
	initial_location_id := "",
	initial_location_name := "",
	initial_stat_changes := {},
	initial_items: Array[String] = [],
	initial_growth_mark_id := "",
	initial_is_read := false,
	initial_is_favorite := false,
	initial_is_special_memory := false,
	initial_illustration_id := ""
) -> void:
	journal_id = initial_journal_id
	activity_record_id = initial_record_id
	date = initial_date
	activity_id = initial_activity_id
	rabbit_name = initial_rabbit_name
	title = initial_title
	content = initial_content
	created_at = TimeManager.get_now() if initial_created_at <= 0.0 else initial_created_at
	journal_type = initial_journal_type
	location_id = initial_location_id
	location_name = initial_location_name
	stat_changes = initial_stat_changes.duplicate(true)
	items.assign(initial_items)
	growth_mark_id = initial_growth_mark_id
	is_read = initial_is_read
	is_favorite = initial_is_favorite
	is_special_memory = initial_is_special_memory
	illustration_id = initial_illustration_id

func to_dict() -> Dictionary:
	return {
		"journal_id": journal_id,
		"journal_type": journal_type,
		"rabbit_name": rabbit_name,
		"activity_record_id": activity_record_id,
		"date": date,
		"activity_id": activity_id,
		"location_id": location_id,
		"location_name": location_name,
		"created_at": created_at,
		"title": title,
		"content": content,
		"stat_changes": stat_changes.duplicate(true),
		"items": items.duplicate(),
		"growth_mark_id": growth_mark_id,
		"is_read": is_read,
		"is_favorite": is_favorite,
		"is_special_memory": is_special_memory,
		"illustration_id": illustration_id,
		"village_event_id": village_event_id,
		"building_id": building_id,
		"construction_record_id": construction_record_id,
		"building_use_record_id": building_use_record_id,
		"notice_id": notice_id,
		"notice_date": notice_date,
		"farm_cycle_id": farm_cycle_id,
		"harvest_record_id": harvest_record_id,
		"village_stage": village_stage,
		"is_village_memory": is_village_memory,
		"food_use_record_id": food_use_record_id,
		"food_id": food_id,
		"reward_record_id": reward_record_id,
		"item_id": item_id,
		"item_discovery_id": item_discovery_id,
		"life_event_id": life_event_id,
		"growth_path": growth_path,
		"growth_stage": growth_stage,
		"growth_event_id": growth_event_id,
		"is_life_memory": is_life_memory,
		"purchase_record_id": purchase_record_id,
		"shop_id": shop_id,
		"product_id": product_id,
		"cooking_record_id": cooking_record_id,
		"recipe_id": recipe_id,
		"life_location_id": life_location_id,
		"life_location_activity_id": life_location_activity_id,
		"shop_event_id": shop_event_id,
		"cooking_event_id": cooking_event_id,
		"picnic_event_id": picnic_event_id,
		"building_slot_id": building_slot_id,
		"construction_id": construction_id,
		"cafe_activity_id": cafe_activity_id,
		"village_progress_event_id": village_progress_event_id,
		"growth_form": growth_form,
		"growth_direction_choice_id": growth_direction_choice_id,
		"final_growth_record_id": final_growth_record_id,
		"final_form": final_form,
		"life_profile_snapshot_id": life_profile_snapshot_id,
		"ending_id": ending_id,
		"ending_snapshot_id": ending_snapshot_id,
		"is_post_ending": is_post_ending,
		"resident_id": resident_id,
		"relationship_state": relationship_state,
		"shared_activity_id": shared_activity_id,
		"resident_event_id": resident_event_id,
		"resident_interaction_id": resident_interaction_id,
		"invitation_id": invitation_id
	}

static func from_dict(data: Dictionary) -> JournalEntry:
	var loaded_items: Array[String] = []
	for item: Variant in data.get("items", data.get("Items", [])):
		loaded_items.append(str(item))
	var loaded_stats: Dictionary = {}
	var raw_stats: Variant = data.get("stat_changes", data.get("StatChanges", {}))
	if raw_stats is Dictionary:
		loaded_stats = raw_stats.duplicate(true)
	var activity_id_loaded := str(data.get("activity_id", data.get("ActivityId", "")))
	var location_id_loaded := str(data.get("location_id", data.get("LocationId", "")))
	var location_name_loaded := str(data.get("location_name", data.get("LocationName", "")))
	if location_id_loaded.is_empty():
		match activity_id_loaded:
			"forest_walk", "forest_explore":
				location_id_loaded = "forest"
				location_name_loaded = "森林"
			"fishing":
				location_id_loaded = "lake"
				location_name_loaded = "湖邊"
			"home_rest":
				location_id_loaded = "home"
				location_name_loaded = "家裡"
	var type_loaded := str(data.get("journal_type", data.get("JournalType", "activity")))
	if activity_id_loaded == "home_rest" and type_loaded == "activity":
		type_loaded = "home"
	var entry := JournalEntry.new(
		str(data.get("journal_id", data.get("JournalId", ""))),
		str(data.get("activity_record_id", data.get("ActivityRecordId", ""))),
		str(data.get("date", data.get("CreatedDate", ""))),
		activity_id_loaded,
		str(data.get("rabbit_name", data.get("RabbitName", ""))),
		str(data.get("title", data.get("Title", ""))),
		str(data.get("content", data.get("Content", ""))),
		float(data.get("created_at", data.get("CreatedAt", 0.0))),
		type_loaded,
		location_id_loaded,
		location_name_loaded,
		loaded_stats,
		loaded_items,
		str(data.get("growth_mark_id", data.get("GrowthMarkId", ""))),
		bool(data.get("is_read", data.get("IsRead", false))),
		bool(data.get("is_favorite", data.get("IsFavorite", false))),
		bool(data.get("is_special_memory", data.get("IsSpecialMemory", false))),
		str(data.get("illustration_id", data.get("IllustrationId", "")))
	)
	entry.village_event_id = str(data.get("village_event_id", data.get("VillageEventId", "")))
	entry.building_id = str(data.get("building_id", data.get("BuildingId", "")))
	entry.construction_record_id = str(data.get("construction_record_id", data.get("ConstructionRecordId", "")))
	entry.building_use_record_id = str(data.get("building_use_record_id", data.get("BuildingUseRecordId", "")))
	entry.notice_id = str(data.get("notice_id", data.get("NoticeId", "")))
	entry.notice_date = str(data.get("notice_date", data.get("NoticeDate", "")))
	entry.farm_cycle_id = str(data.get("farm_cycle_id", data.get("FarmCycleId", "")))
	entry.harvest_record_id = str(data.get("harvest_record_id", data.get("HarvestRecordId", "")))
	entry.village_stage = maxi(0, int(data.get("village_stage", data.get("VillageStage", 0))))
	entry.is_village_memory = bool(data.get("is_village_memory", data.get("IsVillageMemory", false)))
	entry.food_use_record_id = str(data.get("food_use_record_id", data.get("FoodUseRecordId", "")))
	entry.food_id = str(data.get("food_id", data.get("FoodId", "")))
	entry.reward_record_id = str(data.get("reward_record_id", data.get("RewardRecordId", "")))
	entry.item_id = str(data.get("item_id", data.get("ItemId", "")))
	entry.item_discovery_id = str(data.get("item_discovery_id", data.get("ItemDiscoveryId", "")))
	entry.life_event_id = str(data.get("life_event_id", data.get("LifeEventId", "")))
	entry.growth_path = str(data.get("growth_path", data.get("GrowthPath", "")))
	entry.growth_stage = maxi(0, int(data.get("growth_stage", data.get("GrowthStage", 0))))
	entry.growth_event_id = str(data.get("growth_event_id", data.get("GrowthEventId", "")))
	entry.is_life_memory = bool(data.get("is_life_memory", data.get("IsLifeMemory", false)))
	entry.purchase_record_id = str(data.get("purchase_record_id", data.get("PurchaseRecordId", "")))
	entry.shop_id = str(data.get("shop_id", data.get("ShopId", "")))
	entry.product_id = str(data.get("product_id", data.get("ProductId", "")))
	entry.cooking_record_id = str(data.get("cooking_record_id", data.get("CookingRecordId", "")))
	entry.recipe_id = str(data.get("recipe_id", data.get("RecipeId", "")))
	entry.life_location_id = str(data.get("life_location_id", data.get("LifeLocationId", "")))
	entry.life_location_activity_id = str(data.get("life_location_activity_id", data.get("LifeLocationActivityId", "")))
	entry.shop_event_id = str(data.get("shop_event_id", data.get("ShopEventId", "")))
	entry.cooking_event_id = str(data.get("cooking_event_id", data.get("CookingEventId", "")))
	entry.picnic_event_id = str(data.get("picnic_event_id", data.get("PicnicEventId", "")))
	entry.building_slot_id = str(data.get("building_slot_id", data.get("BuildingSlotId", data.get("slot_id", ""))))
	entry.construction_id = str(data.get("construction_id", data.get("ConstructionId", entry.construction_record_id)))
	entry.growth_form = str(data.get("growth_form", data.get("GrowthForm", "none")))
	if entry.construction_record_id.is_empty() and not entry.construction_id.is_empty():
		entry.construction_record_id = entry.construction_id
	if entry.construction_id.is_empty() and not entry.construction_record_id.is_empty():
		entry.construction_id = entry.construction_record_id
	entry.cafe_activity_id = str(data.get("cafe_activity_id", data.get("CafeActivityId", "")))
	entry.village_progress_event_id = str(data.get("village_progress_event_id", data.get("VillageProgressEventId", "")))
	entry.growth_direction_choice_id = str(data.get("growth_direction_choice_id", ""))
	entry.final_growth_record_id = str(data.get("final_growth_record_id", ""))
	entry.final_form = str(data.get("final_form", "none"))
	entry.life_profile_snapshot_id = str(data.get("life_profile_snapshot_id", ""))
	entry.ending_id = str(data.get("ending_id", ""))
	entry.ending_snapshot_id = str(data.get("ending_snapshot_id", ""))
	entry.is_post_ending = bool(data.get("is_post_ending", false))
	entry.resident_id = str(data.get("resident_id", data.get("ResidentId", "")))
	entry.relationship_state = str(data.get("relationship_state", data.get("RelationshipState", "")))
	entry.shared_activity_id = str(data.get("shared_activity_id", data.get("SharedActivityId", "")))
	entry.resident_event_id = str(data.get("resident_event_id", data.get("ResidentEventId", "")))
	entry.resident_interaction_id = str(data.get("resident_interaction_id", data.get("ResidentInteractionId", "")))
	entry.invitation_id = str(data.get("invitation_id", data.get("InvitationId", "")))
	return entry

func is_valid() -> bool:
	if journal_id.is_empty() or title.is_empty() or content.is_empty():
		return false
	match journal_type:
		"growth":
			return not growth_mark_id.is_empty()
		"activity", "home":
			return not activity_record_id.is_empty() and not activity_id.is_empty()
		"village_event":
			return not village_event_id.is_empty()
		"construction", "building_complete":
			return not construction_record_id.is_empty() and not building_id.is_empty()
		"building_use":
			return not building_use_record_id.is_empty() and not building_id.is_empty()
		"notice":
			return not notice_id.is_empty() and not notice_date.is_empty()
		"farm_growth":
			return not farm_cycle_id.is_empty()
		"harvest":
			return not harvest_record_id.is_empty() and not farm_cycle_id.is_empty()
		"village_growth":
			return village_stage > 0
		"food_use":
			return not food_use_record_id.is_empty() and not food_id.is_empty()
		"needs":
			return not date.is_empty()
		"item_discovery":
			return not item_id.is_empty() and not item_discovery_id.is_empty()
		"life_event", "week5_finale":
			return not life_event_id.is_empty()
		"growth_event":
			return not growth_event_id.is_empty() or not growth_mark_id.is_empty()
		"growth_lifestyle":
			return not growth_path.is_empty() and growth_stage > 0
		"first_purchase", "shopping":
			return not purchase_record_id.is_empty()
		"product_unlock":
			return not product_id.is_empty()
		"new_food", "food_reaction":
			return not food_use_record_id.is_empty() and not food_id.is_empty()
		"first_cooking", "cooking", "recipe_discovery":
			return not cooking_record_id.is_empty() and not recipe_id.is_empty()
		"picnic", "picnic_food":
			return not life_location_id.is_empty() and not life_location_activity_id.is_empty()
		"shop_event":
			return not shop_event_id.is_empty()
		"cooking_event":
			return not cooking_event_id.is_empty()
		"picnic_event":
			return not picnic_event_id.is_empty()
		"week6_finale":
			return not life_event_id.is_empty()
		"building_unlock":
			return not building_id.is_empty()
		"building_placement":
			return not building_id.is_empty() and not building_slot_id.is_empty()
		"week7_construction":
			return not construction_id.is_empty() and not building_id.is_empty()
		"cafe_complete":
			return building_id == "cafe"
		"cafe_activity":
			return not activity_record_id.is_empty() and not cafe_activity_id.is_empty()
		"cafe_event":
			return not life_event_id.is_empty()
		"week7_growth":
			return not growth_event_id.is_empty() and growth_stage > 0
		"growth_reaction":
			return not activity_record_id.is_empty() and not growth_path.is_empty() and growth_stage > 0
		"village_progress":
			return not village_progress_event_id.is_empty()
		"week7_finale":
			return not life_event_id.is_empty()
		"growth_direction", "balanced":
			return not growth_direction_choice_id.is_empty()
		"final_growth":
			return not final_growth_record_id.is_empty() and final_form in ["forest_rabbit", "lakeside_rabbit"]
		"final_reaction", "post_ending":
			return not activity_record_id.is_empty() or not life_location_id.is_empty()
		"village_stage1":
			return village_progress_event_id == "village_stage1_complete_001"
		"life_resume":
			return not life_profile_snapshot_id.is_empty()
		"ending":
			return not ending_id.is_empty()
		"resident_arrival", "resident_first_meeting", "resident_interaction", "resident_visit", "resident_gift", "resident_letter", "resident_first_friend", "resident_reaction":
			return not resident_id.is_empty() and (not resident_event_id.is_empty() or not resident_interaction_id.is_empty())
		"resident_shared_activity":
			return not resident_id.is_empty() and not shared_activity_id.is_empty()
		"resident_invitation":
			return not resident_id.is_empty() and not invitation_id.is_empty()
	return true

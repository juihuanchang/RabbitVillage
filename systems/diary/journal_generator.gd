class_name JournalGenerator
extends RefCounted

const TEMPLATE_PATHS := {
	"forest_walk": "res://data/journals/forest_walk.json",
	"forest_explore": "res://data/journals/forest_explore.json",
	"fishing": "res://data/journals/fishing.json",
	"home_rest": "res://data/journals/home_rest.json"
}
const LEAF_MARK_PATH := "res://data/journals/leaf_mark.json"
const VILLAGE_EVENT_PATH := "res://data/journals/week4/village_events.json"
const CONSTRUCTION_PATH := "res://data/journals/week4/construction.json"
const REST_PAVILION_PATH := "res://data/journals/week4/rest_pavilion.json"
const FARM_PATH := "res://data/journals/week4/farm.json"
const HARVEST_PATH := "res://data/journals/week4/harvest.json"

const FOOD_PATH := "res://data/journals/week5/carrot_eating.json"
const NEEDS_PATH := "res://data/journals/week5/needs.json"
const ITEM_DISCOVERY_PATH := "res://data/journals/week5/item_discovery.json"
const ITEM_MILESTONE_PATH := "res://data/journals/week5/item_milestones.json"
const SPROUT_PATH := "res://data/journals/week5/sprout_mark.json"
const LAKESIDE_PATH := "res://data/journals/week5/lakeside_interest.json"
const GROWTH_EVENTS_PATH := "res://data/journals/week5/growth_events.json"
const FINALE_PATH := "res://data/journals/week5/week5_finale.json"

static func generate(active: ActiveActivityData, journal_id: String) -> JournalEntry:
	if active == null or active.rabbit == null or active.activity == null:
		return null
	var template := _pick_activity_template(active.activity.activity_id)
	var at := active.completed_at if active.completed_at > 0.0 else TimeManager.get_now()
	return JournalEntry.new(
		journal_id,
		active.activity_record_id,
		_format_date(at),
		active.activity.activity_id,
		active.rabbit.rabbit_name,
		str(template.get("title", "%s完成" % active.activity.activity_name)),
		_format_content(str(template.get("content", "{rabbit_name} 完成了%s。" % active.activity.activity_name)), active.rabbit.rabbit_name),
		at,
		"home" if active.activity.activity_id == "home_rest" else "activity",
		active.activity.location_id,
		active.activity.location_name,
		active.get_stat_changes(),
		active.activity.reward_items
	)

static func generate_growth_journal(rabbit_name: String, journal_id: String, mark_id: String, created_at: float = -1.0) -> JournalEntry:
	if mark_id != "leaf_mark":
		return null
	var data := _load_json(LEAF_MARK_PATH)
	if data.is_empty():
		return null
	var at := TimeManager.get_now() if created_at <= 0.0 else created_at
	return JournalEntry.new(
		journal_id,
		"",
		_format_date(at),
		"",
		rabbit_name,
		str(data.get("title", "耳朵旁的小葉子")),
		_format_content(str(data.get("content", "")), rabbit_name),
		at,
		"growth",
		str(data.get("location_id", "forest")),
		str(data.get("location_name", "森林")),
		{},
		[],
		mark_id,
		false,
		false,
		true,
		str(data.get("illustration_id", "leaf_mark_memory"))
	)

static func generate_village_event_journal(rabbit_name: String, journal_id: String, event_id: String, at: float, stage: int) -> JournalEntry:
	var data := _load_json(VILLAGE_EVENT_PATH)
	var all_templates: Variant = data.get("templates", {})
	if not (all_templates is Dictionary) or not all_templates.has(event_id):
		return null
	var template: Dictionary = all_templates[event_id]
	var entry := _base(journal_id, rabbit_name, "village_event", at, str(template.get("title", "村莊事件")), str(template.get("content", "")))
	entry.village_event_id = event_id
	entry.village_stage = stage
	entry.is_village_memory = true
	return entry

static func generate_construction_journal(rabbit_name: String, journal_id: String, record_id: String, building_id: String, phase: String, at: float, stage: int) -> JournalEntry:
	var data := _load_json(CONSTRUCTION_PATH)
	var all_templates: Variant = data.get("templates", {})
	if not (all_templates is Dictionary) or not all_templates.has(building_id):
		return null
	var building_templates: Variant = all_templates[building_id]
	if not (building_templates is Dictionary) or not building_templates.has(phase):
		return null
	var template: Dictionary = building_templates[phase]
	var journal_type := "construction" if phase == "start" else "building_complete"
	var entry := _base(journal_id, rabbit_name, journal_type, at, str(template.get("title", "建築紀錄")), str(template.get("content", "")))
	entry.building_id = building_id
	entry.construction_record_id = record_id
	entry.village_stage = stage
	entry.is_village_memory = journal_type == "building_complete"
	return entry

static func generate_building_use_journal(rabbit_name: String, journal_id: String, result: BuildingUseResult, first: bool, stage: int) -> JournalEntry:
	if result == null or result.building_id != "rest_pavilion":
		return null
	var data := _load_json(REST_PAVILION_PATH)
	var template: Dictionary = {}
	if first:
		if data.get("first_use", {}) is Dictionary:
			template = data.get("first_use", {})
	else:
		template = _pick_dictionary(data.get("general", []))
	if template.is_empty():
		return null
	var entry := _base(journal_id, rabbit_name, "building_use", result.completed_at, str(template.get("title", "休息亭時光")), str(template.get("content", "")))
	entry.building_id = result.building_id
	entry.building_use_record_id = result.building_use_record_id if not result.building_use_record_id.is_empty() else result.interaction_record_id
	entry.village_stage = stage
	entry.stat_changes = {"energy": result.energy_change, "mood": result.mood_change, "intimacy": result.intimacy_change}
	entry.is_special_memory = first
	entry.is_village_memory = first
	return entry

static func generate_notice_journal(rabbit_name: String, journal_id: String, notice: DailyNoticeRecord, stage: int) -> JournalEntry:
	if notice == null:
		return null
	var at := notice.first_read_at if notice.first_read_at > 0.0 else notice.generated_at
	var entry := _base(journal_id, rabbit_name, "notice", at, "今天的村莊公告", notice.content)
	entry.notice_id = notice.notice_id
	entry.notice_date = notice.date_key
	entry.village_stage = stage
	return entry

static func generate_farm_growth_journal(rabbit_name: String, journal_id: String, cycle: FarmCycleData, first: bool, stage: int) -> JournalEntry:
	if cycle == null:
		return null
	var data := _load_json(FARM_PATH)
	var template: Dictionary = {}
	if first and data.get("first_growth", {}) is Dictionary:
		template = data.get("first_growth", {})
	else:
		template = _pick_dictionary(data.get("growth", []))
	if template.is_empty():
		return null
	var entry := _base(journal_id, rabbit_name, "farm_growth", cycle.started_at, str(template.get("title", "胡蘿蔔開始生長")), str(template.get("content", "")))
	entry.building_id = "carrot_farm"
	entry.farm_cycle_id = cycle.farm_cycle_id
	entry.village_stage = stage
	entry.is_village_memory = first
	return entry

static func generate_harvest_journal(rabbit_name: String, journal_id: String, result: HarvestResult, first: bool, stage: int) -> JournalEntry:
	if result == null:
		return null
	var data := _load_json(HARVEST_PATH)
	var template: Dictionary = {}
	if first and data.get("first_harvest", {}) is Dictionary:
		template = data.get("first_harvest", {})
	else:
		template = _pick_dictionary(data.get("general", []))
	if template.is_empty():
		return null
	var entry := _base(journal_id, rabbit_name, "harvest", result.harvested_at, str(template.get("title", "胡蘿蔔收成")), str(template.get("content", "")))
	entry.building_id = "carrot_farm"
	entry.farm_cycle_id = result.farm_cycle_id
	entry.harvest_record_id = result.harvest_record_id
	entry.village_stage = stage
	entry.items = ["carrot:%d" % maxi(0, result.amount)]
	entry.is_special_memory = first
	entry.is_village_memory = first
	return entry

static func generate_village_growth_journal(rabbit_name: String, journal_id: String, stage: int, at: float) -> JournalEntry:
	if stage <= 0:
		return null
	var entry := _base(journal_id, rabbit_name, "village_growth", at, "村莊又長大了一點", "{rabbit_name} 發現村莊和以前不太一樣了。新的角落、建築和故事，正在慢慢把這裡變成真正的家。")
	entry.village_stage = stage
	entry.is_village_memory = true
	return entry

# ---------------- Week 5 ----------------

static func generate_food_use_journal(rabbit_name: String, journal_id: String, result: FoodUseResult, first_use: bool) -> JournalEntry:
	if result == null or result.food_use_record_id.is_empty() or result.food_id != "carrot":
		return null
	var data := _load_json(FOOD_PATH)
	var template: Dictionary = {}
	if first_use and data.get("first_use", {}) is Dictionary:
		template = data.get("first_use", {})
	else:
		template = _pick_dictionary(data.get("general", []))
	if template.is_empty():
		return null
	var entry := _base(journal_id, rabbit_name, "food_use", result.used_at, str(template.get("title", "胡蘿蔔時間")), str(template.get("content", "")))
	entry.food_use_record_id = result.food_use_record_id
	entry.food_id = result.food_id
	entry.stat_changes = {"hunger": result.hunger_after - result.hunger_before}
	entry.items = ["%s:-%d" % [result.food_id, maxi(0, result.amount_used)]]
	entry.is_special_memory = first_use
	entry.is_life_memory = first_use
	entry.illustration_id = str(template.get("illustration_id", ""))
	return entry

static func generate_needs_journal(rabbit_name: String, journal_id: String, need_key: String, at: float, stats: Dictionary = {}) -> JournalEntry:
	var data := _load_json(NEEDS_PATH)
	var template := _pick_dictionary(data.get(need_key, []))
	if template.is_empty():
		return null
	var entry := _base(journal_id, rabbit_name, "needs", at, str(template.get("title", "今天的 Amy")), str(template.get("content", "")))
	entry.location_id = "home"
	entry.location_name = "家裡"
	entry.stat_changes = stats.duplicate(true)
	return entry

static func generate_item_discovery_journal(rabbit_name: String, journal_id: String, discovery: ItemDiscoveryHistoryEntry) -> JournalEntry:
	if discovery == null or discovery.discovery_id.is_empty() or discovery.item_id.is_empty():
		return null
	var data := _load_json(ITEM_DISCOVERY_PATH)
	var template := _pick_dictionary(data.get(discovery.item_id, []))
	if template.is_empty():
		return null
	var entry := _base(journal_id, rabbit_name, "item_discovery", discovery.discovered_at, str(template.get("title", "新的發現")), str(template.get("content", "")))
	entry.item_id = discovery.item_id
	entry.item_discovery_id = discovery.discovery_id
	entry.items = ["%s:first" % discovery.item_id]
	if discovery.source_type == "activity_reward":
		entry.reward_record_id = discovery.source_id
	entry.is_special_memory = true
	entry.is_life_memory = true
	return entry

static func generate_life_event_journal(rabbit_name: String, journal_id: String, event_id: String, at: float) -> JournalEntry:
	if event_id.is_empty():
		return null
	if event_id == "village_life_expands_001":
		var finale_data := _load_json(FINALE_PATH)
		if not finale_data.has(event_id) or not (finale_data[event_id] is Dictionary):
			return null
		var finale_template: Dictionary = finale_data[event_id]
		var finale := _base(journal_id, rabbit_name, "week5_finale", at, str(finale_template.get("title", "新的生活")), str(finale_template.get("content", "")))
		finale.life_event_id = event_id
		finale.is_special_memory = true
		finale.is_life_memory = true
		return finale
	var data := _load_json(ITEM_MILESTONE_PATH)
	if not data.has(event_id) or not (data[event_id] is Dictionary):
		return null
	var template: Dictionary = data[event_id]
	var entry := _base(journal_id, rabbit_name, "life_event", at, str(template.get("title", "收藏里程碑")), str(template.get("content", "")))
	entry.life_event_id = event_id
	entry.item_id = _item_id_from_life_event(event_id)
	entry.is_special_memory = true
	entry.is_life_memory = true
	return entry

static func generate_growth_event_journal(
	rabbit_name: String,
	journal_id: String,
	event_id: String,
	growth_path: String,
	growth_stage: int,
	growth_mark_id: String,
	at: float
) -> JournalEntry:
	if event_id.is_empty():
		return null
	var template: Dictionary = {}
	if event_id == "growth_sprout_mark_001":
		var sprout := _load_json(SPROUT_PATH)
		if sprout.get("special", {}) is Dictionary:
			template = sprout.get("special", {})
	elif event_id == "growth_lake_interest_001":
		var lakeside := _load_json(LAKESIDE_PATH)
		if lakeside.get("special", {}) is Dictionary:
			template = lakeside.get("special", {})
	else:
		var data := _load_json(GROWTH_EVENTS_PATH)
		var templates: Variant = data.get("templates", {})
		if templates is Dictionary and templates.has(event_id) and templates[event_id] is Dictionary:
			template = templates[event_id]
	if template.is_empty():
		return null
	var entry := _base(journal_id, rabbit_name, "growth_event", at, str(template.get("title", "新的成長")), str(template.get("content", "")))
	entry.growth_event_id = event_id
	entry.growth_mark_id = growth_mark_id
	entry.growth_path = growth_path
	entry.growth_stage = maxi(0, growth_stage)
	entry.is_special_memory = true
	entry.is_life_memory = true
	entry.illustration_id = str(template.get("illustration_id", ""))
	return entry

static func generate_growth_lifestyle_journal(
	rabbit_name: String,
	journal_id: String,
	growth_path: String,
	growth_stage: int,
	source_record_id: String,
	at: float
) -> JournalEntry:
	var data := _load_json(SPROUT_PATH if growth_path == "forest" else LAKESIDE_PATH)
	var template := _pick_dictionary(data.get("general", []))
	if template.is_empty():
		return null
	var entry := _base(journal_id, rabbit_name, "growth_lifestyle", at, str(template.get("title", "成長後的日常")), str(template.get("content", "")))
	entry.activity_record_id = source_record_id
	entry.growth_path = growth_path
	entry.growth_stage = maxi(0, growth_stage)
	entry.growth_mark_id = "sprout_mark" if growth_path == "forest" else "lake_interest"
	return entry

static func _base(id: String, rabbit_name: String, journal_type: String, at: float, title: String, content: String) -> JournalEntry:
	var time := TimeManager.get_now() if at <= 0.0 else at
	return JournalEntry.new(id, "", _format_date(time), "", rabbit_name, title, _format_content(content, rabbit_name), time, journal_type, "village", "村莊")

static func _pick_activity_template(activity_id: String) -> Dictionary:
	var path := str(TEMPLATE_PATHS.get(activity_id, ""))
	if path.is_empty():
		return {}
	var data := _load_json(path)
	return _pick_dictionary(data.get("templates", []))

static func _pick_dictionary(raw: Variant) -> Dictionary:
	if not (raw is Array) or raw.is_empty():
		return {}
	var picked: Variant = raw.pick_random()
	return picked.duplicate(true) if picked is Dictionary else {}

static func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK or not (json.data is Dictionary):
		return {}
	return json.data

static func _format_content(content: String, rabbit_name: String) -> String:
	return content.replace("{rabbit_name}", rabbit_name)

static func _format_date(timestamp: float) -> String:
	var date := TimeManager.get_local_datetime(timestamp)
	return "%04d/%02d/%02d" % [date.year, date.month, date.day]

static func _item_id_from_life_event(event_id: String) -> String:
	match event_id:
		"life_leaf_collection_001":
			return "leaf"
		"life_twig_collection_001":
			return "twig"
		"life_stone_collection_001":
			return "small_stone"
		"life_driftwood_collection_001":
			return "driftwood"
	return ""

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

# Week 6 journal templates.
const FIRST_PURCHASE_PATH := "res://data/journals/week6/first_purchase.json"
const SHOPPING_PATH := "res://data/journals/week6/shopping.json"
const PRODUCT_UNLOCK_PATH := "res://data/journals/week6/product_unlock.json"
const NEW_FOOD_PATH := "res://data/journals/week6/new_food.json"
const FOOD_REACTIONS_PATH := "res://data/journals/week6/food_reactions.json"
const FIRST_COOKING_PATH := "res://data/journals/week6/first_cooking.json"
const COOKING_PATH := "res://data/journals/week6/cooking.json"
const RECIPE_DISCOVERY_PATH := "res://data/journals/week6/recipe_discovery.json"
const PICNIC_PATH := "res://data/journals/week6/picnic.json"
const PICNIC_FOOD_PATH := "res://data/journals/week6/picnic_food.json"
const SHOP_EVENTS_PATH := "res://data/journals/week6/shop_events.json"
const COOKING_EVENTS_PATH := "res://data/journals/week6/cooking_events.json"
const PICNIC_EVENTS_PATH := "res://data/journals/week6/picnic_events.json"
const WEEK6_FINALE_PATH := "res://data/journals/week6/week6_finale.json"

# Week 7 journal templates.
const WEEK7_BUILDING_UNLOCK_PATH := "res://data/journals/week7/building_unlock.json"
const WEEK7_BUILDING_PLACEMENT_PATH := "res://data/journals/week7/building_placement.json"
const WEEK7_CONSTRUCTION_PATH := "res://data/journals/week7/construction.json"
const WEEK7_CAFE_COMPLETE_PATH := "res://data/journals/week7/cafe_complete.json"
const WEEK7_CAFE_HOT_DRINK_PATH := "res://data/journals/week7/cafe_hot_drink.json"
const WEEK7_CAFE_HELP_SERVE_PATH := "res://data/journals/week7/cafe_help_serve.json"
const WEEK7_CAFE_RELAX_PATH := "res://data/journals/week7/cafe_relax.json"
const WEEK7_CAFE_EVENTS_PATH := "res://data/journals/week7/cafe_events.json"
const WEEK7_FOREST_STAGE3_PATH := "res://data/journals/week7/forest_stage3.json"
const WEEK7_LAKESIDE_STAGE2_PATH := "res://data/journals/week7/lakeside_stage2.json"
const WEEK7_GROWTH_REACTIONS_PATH := "res://data/journals/week7/growth_reactions.json"
const WEEK7_VILLAGE_PROGRESS_PATH := "res://data/journals/week7/village_progress.json"
const WEEK7_FINALE_PATH := "res://data/journals/week7/week7_finale.json"

# Week 8 final-growth / life-resume / ending templates.
const WEEK8_GROWTH_DIRECTION_PATH := "res://data/journals/week8/growth_direction.json"
const WEEK8_FOREST_FINAL_PATH := "res://data/journals/week8/forest_final.json"
const WEEK8_LAKESIDE_FINAL_PATH := "res://data/journals/week8/lakeside_final.json"
const WEEK8_BALANCED_PATH := "res://data/journals/week8/balanced.json"
const WEEK8_FINAL_HOME_PATH := "res://data/journals/week8/final_home.json"
const WEEK8_FINAL_FOREST_PATH := "res://data/journals/week8/final_forest.json"
const WEEK8_FINAL_LAKESIDE_PATH := "res://data/journals/week8/final_lakeside.json"
const WEEK8_FINAL_CAFE_PATH := "res://data/journals/week8/final_cafe.json"
const WEEK8_FINAL_PICNIC_PATH := "res://data/journals/week8/final_picnic.json"
const WEEK8_LIFE_RESUME_PATH := "res://data/journals/week8/life_resume.json"
const WEEK8_VILLAGE_STAGE1_PATH := "res://data/journals/week8/village_stage1.json"
const WEEK8_ENDING_PATH := "res://data/journals/week8/ending.json"
const WEEK8_POST_ENDING_PATH := "res://data/journals/week8/post_ending.json"

# Week 9 resident / relationship templates.
const RESIDENT_FIRST_MEETING_PATH := "res://data/journals/residents/first_meeting.json"
const RESIDENT_CAFE_OWNER_PATH := "res://data/journals/residents/cafe_owner.json"
const RESIDENT_CONVERSATION_PATH := "res://data/journals/residents/conversation.json"
const RESIDENT_SHARED_CAFE_PATH := "res://data/journals/residents/shared_cafe.json"
const RESIDENT_SHARED_FOREST_PATH := "res://data/journals/residents/shared_forest.json"
const RESIDENT_SHARED_PICNIC_PATH := "res://data/journals/residents/shared_picnic.json"
const RESIDENT_HOME_VISIT_PATH := "res://data/journals/residents/home_visit.json"
const RESIDENT_GIFT_PATH := "res://data/journals/residents/gift.json"
const RESIDENT_LETTER_PATH := "res://data/journals/residents/letter.json"
const RESIDENT_INVITATION_PATH := "res://data/journals/residents/invitation.json"
const RESIDENT_FIRST_FRIEND_PATH := "res://data/journals/residents/first_friend.json"
const RESIDENT_FOREST_REACTION_PATH := "res://data/journals/residents/forest_reaction.json"
const RESIDENT_LAKESIDE_REACTION_PATH := "res://data/journals/residents/lakeside_reaction.json"
const RESIDENT_BALANCED_REACTION_PATH := "res://data/journals/residents/balanced_reaction.json"

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


# ---------------- Week 6 ----------------

static func generate_first_purchase_journal(rabbit_name: String, journal_id: String, result: PurchaseResult) -> JournalEntry:
	if result == null or result.purchase_record_id.is_empty():
		return null
	var data := _load_json(FIRST_PURCHASE_PATH)
	var template: Variant = data.get("template", {})
	if not (template is Dictionary) or template.is_empty():
		return null
	var entry := _base(journal_id, rabbit_name, "first_purchase", result.purchased_at, str(template.get("title", "第一次購物")), str(template.get("content", "")))
	entry.purchase_record_id = result.purchase_record_id
	entry.shop_id = "village_shop"
	entry.product_id = result.product_id
	entry.item_id = result.item_id
	entry.items = ["%s:+%d" % [result.item_id, maxi(0, result.quantity)]]
	entry.is_special_memory = true
	entry.is_life_memory = true
	return entry

static func generate_shopping_journal(rabbit_name: String, journal_id: String, result: PurchaseResult) -> JournalEntry:
	if result == null or result.purchase_record_id.is_empty():
		return null
	var data := _load_json(SHOPPING_PATH)
	var template := _pick_dictionary(data.get("general", []))
	if template.is_empty():
		return null
	var entry := _base(journal_id, rabbit_name, "shopping", result.purchased_at, str(template.get("title", "今天的小店")), str(template.get("content", "")))
	entry.purchase_record_id = result.purchase_record_id
	entry.shop_id = "village_shop"
	entry.product_id = result.product_id
	entry.item_id = result.item_id
	entry.items = ["%s:+%d" % [result.item_id, maxi(0, result.quantity)]]
	return entry

static func generate_product_unlock_journal(rabbit_name: String, journal_id: String, product: ShopProductData) -> JournalEntry:
	if product == null or product.product_id.is_empty():
		return null
	var data := _load_json(PRODUCT_UNLOCK_PATH)
	var templates: Variant = data.get("products", {})
	if not (templates is Dictionary) or not templates.has(product.product_id) or not (templates[product.product_id] is Dictionary):
		return null
	var template: Dictionary = templates[product.product_id]
	var entry := _base(journal_id, rabbit_name, "product_unlock", product.unlocked_at, str(template.get("title", "小店的新商品")), str(template.get("content", "")))
	entry.shop_id = "village_shop"
	entry.product_id = product.product_id
	entry.item_id = product.item_id
	entry.is_special_memory = true
	entry.is_life_memory = true
	return entry

static func generate_week6_food_journal(rabbit_name: String, journal_id: String, result: FoodUseResult, first_use: bool) -> JournalEntry:
	if result == null or result.food_use_record_id.is_empty() or result.food_id == "carrot":
		return null
	var path := NEW_FOOD_PATH if first_use else FOOD_REACTIONS_PATH
	var data := _load_json(path)
	var foods: Variant = data.get("foods", {})
	if not (foods is Dictionary) or not foods.has(result.food_id):
		return null
	var template: Dictionary = {}
	if first_use and foods[result.food_id] is Dictionary:
		template = foods[result.food_id]
	elif not first_use and foods[result.food_id] is Array:
		template = _pick_dictionary(foods[result.food_id])
	if template.is_empty():
		return null
	var entry := _base(journal_id, rabbit_name, "new_food" if first_use else "food_reaction", result.used_at, str(template.get("title", "新的味道")), str(template.get("content", "")))
	entry.food_use_record_id = result.food_use_record_id
	entry.food_id = result.food_id
	entry.item_id = result.food_id
	entry.stat_changes = {"hunger": result.hunger_change, "energy": result.energy_change, "mood": result.mood_change}
	entry.items = ["%s:-%d" % [result.food_id, maxi(0, result.amount_used)]]
	entry.is_special_memory = first_use
	entry.is_life_memory = first_use
	return entry

static func generate_first_cooking_journal(rabbit_name: String, journal_id: String, result: CookingResult, recipe_id: String) -> JournalEntry:
	if result == null or result.cooking_record_id.is_empty():
		return null
	var data := _load_json(FIRST_COOKING_PATH)
	var template: Variant = data.get("template", {})
	if not (template is Dictionary) or template.is_empty():
		return null
	var entry := _base(journal_id, rabbit_name, "first_cooking", result.cooked_at, str(template.get("title", "第一次料理")), str(template.get("content", "")))
	entry.cooking_record_id = result.cooking_record_id
	entry.recipe_id = recipe_id
	entry.item_id = result.result_item_id
	entry.items = ["%s:+%d" % [result.result_item_id, maxi(0, result.result_amount)]]
	entry.is_special_memory = true
	entry.is_life_memory = true
	return entry

static func generate_cooking_journal(rabbit_name: String, journal_id: String, result: CookingResult, recipe_id: String) -> JournalEntry:
	if result == null or result.cooking_record_id.is_empty():
		return null
	var data := _load_json(COOKING_PATH)
	var template := _pick_dictionary(data.get("general", []))
	if template.is_empty():
		return null
	var entry := _base(journal_id, rabbit_name, "cooking", result.cooked_at, str(template.get("title", "料理完成")), str(template.get("content", "")))
	entry.cooking_record_id = result.cooking_record_id
	entry.recipe_id = recipe_id
	entry.item_id = result.result_item_id
	entry.items = ["%s:+%d" % [result.result_item_id, maxi(0, result.result_amount)]]
	return entry

static func generate_recipe_discovery_journal(rabbit_name: String, journal_id: String, result: CookingResult, recipe_id: String) -> JournalEntry:
	if result == null or result.cooking_record_id.is_empty() or recipe_id.is_empty():
		return null
	var data := _load_json(RECIPE_DISCOVERY_PATH)
	var recipes: Variant = data.get("recipes", {})
	if not (recipes is Dictionary) or not recipes.has(recipe_id):
		return null
	var template := _pick_dictionary(recipes[recipe_id])
	if template.is_empty():
		return null
	var entry := _base(journal_id, rabbit_name, "recipe_discovery", result.cooked_at, str(template.get("title", "新的料理")), str(template.get("content", "")))
	entry.cooking_record_id = result.cooking_record_id
	entry.recipe_id = recipe_id
	entry.item_id = result.result_item_id
	entry.is_special_memory = true
	entry.is_life_memory = true
	return entry

static func generate_picnic_journal(rabbit_name: String, journal_id: String, result: LifeLocationResult) -> JournalEntry:
	if result == null or result.location_record_id.is_empty():
		return null
	var data := _load_json(PICNIC_PATH)
	var template := _pick_dictionary(data.get("general", []))
	if template.is_empty():
		return null
	var entry := _base(journal_id, rabbit_name, "picnic", result.completed_at, str(template.get("title", "野餐區的時間")), str(template.get("content", "")))
	entry.life_location_id = result.location_record_id
	entry.life_location_activity_id = result.activity_id
	entry.location_id = result.location_id
	entry.location_name = "休憩野餐區"
	entry.stat_changes = {"energy": result.energy_change, "mood": result.mood_change, "intimacy": result.intimacy_change}
	return entry

static func generate_picnic_food_journal(rabbit_name: String, journal_id: String, result: LifeLocationResult, food_id: String) -> JournalEntry:
	if result == null or result.location_record_id.is_empty() or food_id.is_empty():
		return null
	var data := _load_json(PICNIC_FOOD_PATH)
	var foods: Variant = data.get("foods", {})
	if not (foods is Dictionary) or not foods.has(food_id) or not (foods[food_id] is Dictionary):
		return null
	var template: Dictionary = foods[food_id]
	var entry := _base(journal_id, rabbit_name, "picnic_food", result.completed_at, str(template.get("title", "野餐時吃點東西")), str(template.get("content", "")))
	entry.life_location_id = result.location_record_id
	entry.life_location_activity_id = result.activity_id
	entry.location_id = result.location_id
	entry.location_name = "休憩野餐區"
	entry.food_id = food_id
	entry.item_id = food_id
	return entry

static func generate_week6_event_journal(rabbit_name: String, journal_id: String, event_id: String, at: float) -> JournalEntry:
	if event_id.is_empty():
		return null
	var path := ""
	var journal_type := ""
	if event_id.begins_with("shop_"):
		path = SHOP_EVENTS_PATH
		journal_type = "shop_event"
	elif event_id.begins_with("cooking_"):
		path = COOKING_EVENTS_PATH
		journal_type = "cooking_event"
	elif event_id.begins_with("picnic_"):
		path = PICNIC_EVENTS_PATH
		journal_type = "picnic_event"
	elif event_id == "village_daily_life_001":
		var finale_data := _load_json(WEEK6_FINALE_PATH)
		if not finale_data.has(event_id) or not (finale_data[event_id] is Dictionary):
			return null
		var finale_template: Dictionary = finale_data[event_id]
		var finale := _base(journal_id, rabbit_name, "week6_finale", at, str(finale_template.get("title", "村莊的日常")), str(finale_template.get("content", "")))
		finale.life_event_id = event_id
		finale.is_special_memory = true
		finale.is_life_memory = true
		return finale
	else:
		return null
	var data := _load_json(path)
	var events: Variant = data.get("events", {})
	if not (events is Dictionary) or not events.has(event_id) or not (events[event_id] is Dictionary):
		return null
	var template: Dictionary = events[event_id]
	var entry := _base(journal_id, rabbit_name, journal_type, at, str(template.get("title", "生活事件")), str(template.get("content", "")))
	entry.life_event_id = event_id
	if journal_type == "shop_event":
		entry.shop_event_id = event_id
	elif journal_type == "cooking_event":
		entry.cooking_event_id = event_id
	else:
		entry.picnic_event_id = event_id
	entry.is_special_memory = true
	entry.is_life_memory = true
	return entry

# ---------------- Week 7 ----------------

static func generate_week7_building_unlock_journal(rabbit_name: String, journal_id: String, entry: BuildingUnlockHistoryEntry) -> JournalEntry:
	if entry == null or entry.building_id != "cafe":
		return null
	var data := _load_json(WEEK7_BUILDING_UNLOCK_PATH)
	var template := _pick_dictionary(data.get("templates", []))
	if template.is_empty():
		return null
	var journal := _base(journal_id, rabbit_name, "building_unlock", entry.unlocked_at, str(template.get("title", "咖啡館解鎖")), str(template.get("content", "")))
	journal.building_id = "cafe"
	journal.life_event_id = entry.source_event_id
	journal.is_special_memory = true
	journal.is_village_memory = true
	return journal

static func generate_week7_building_placement_journal(rabbit_name: String, journal_id: String, entry: BuildingPlacementHistoryEntry) -> JournalEntry:
	if entry == null or entry.building_id != "cafe" or entry.slot_id.is_empty():
		return null
	var data := _load_json(WEEK7_BUILDING_PLACEMENT_PATH)
	var template: Dictionary = {}
	var by_slot: Variant = data.get("by_slot", {})
	if by_slot is Dictionary and by_slot.has(entry.slot_id):
		template = _pick_dictionary(by_slot[entry.slot_id])
	if template.is_empty():
		template = _pick_dictionary(data.get("general", []))
	if template.is_empty():
		return null
	var journal := _base(journal_id, rabbit_name, "building_placement", entry.placed_at, str(template.get("title", "咖啡館的位置")), str(template.get("content", "")))
	journal.building_id = "cafe"
	journal.building_slot_id = entry.slot_id
	journal.location_id = entry.slot_id
	journal.location_name = "村莊建築位"
	return journal

static func generate_week7_construction_journal(rabbit_name: String, journal_id: String, entry: ConstructionHistoryEntry) -> JournalEntry:
	if entry == null or entry.building_id != "cafe" or entry.construction_record_id.is_empty():
		return null
	var data := _load_json(WEEK7_CONSTRUCTION_PATH)
	var template := _pick_dictionary(data.get("templates", []))
	if template.is_empty():
		return null
	var journal := _base(journal_id, rabbit_name, "week7_construction", entry.started_at, str(template.get("title", "咖啡館施工")), str(template.get("content", "")))
	journal.building_id = "cafe"
	journal.building_slot_id = entry.slot_id
	journal.construction_id = entry.construction_record_id
	journal.construction_record_id = entry.construction_record_id
	return journal

static func generate_week7_cafe_complete_journal(rabbit_name: String, journal_id: String, entry: ConstructionHistoryEntry) -> JournalEntry:
	if entry == null or entry.building_id != "cafe" or entry.construction_record_id.is_empty():
		return null
	var data := _load_json(WEEK7_CAFE_COMPLETE_PATH)
	var template := _pick_dictionary(data.get("templates", []))
	if template.is_empty():
		return null
	var at := entry.completed_at if entry.completed_at > 0.0 else entry.complete_at
	var journal := _base(journal_id, rabbit_name, "cafe_complete", at, str(template.get("title", "咖啡館完成")), str(template.get("content", "")))
	journal.building_id = "cafe"
	journal.building_slot_id = entry.slot_id
	journal.construction_id = entry.construction_record_id
	journal.construction_record_id = entry.construction_record_id
	journal.is_special_memory = true
	journal.is_village_memory = true
	return journal

static func generate_week7_cafe_activity_journal(rabbit_name: String, journal_id: String, entry: CafeActivityHistoryEntry) -> JournalEntry:
	if entry == null or entry.activity_record_id.is_empty():
		return null
	var path := ""
	match entry.cafe_activity_id:
		"cafe_hot_drink":
			path = WEEK7_CAFE_HOT_DRINK_PATH
		"cafe_help_serve":
			path = WEEK7_CAFE_HELP_SERVE_PATH
		"cafe_relax":
			path = WEEK7_CAFE_RELAX_PATH
		_:
			return null
	var data := _load_json(path)
	var template := _pick_dictionary(data.get("templates", []))
	if template.is_empty():
		return null
	var journal := _base(journal_id, rabbit_name, "cafe_activity", entry.completed_at, str(template.get("title", "咖啡館時光")), str(template.get("content", "")))
	journal.activity_record_id = entry.activity_record_id
	journal.activity_id = entry.cafe_activity_id
	journal.cafe_activity_id = entry.cafe_activity_id
	journal.location_id = "cafe"
	journal.location_name = "咖啡館"
	journal.stat_changes = {
		"cafe_experience": entry.cafe_experience_change,
		"social_experience": entry.social_experience_change,
		"coin": entry.coin_reward
	}
	return journal

static func generate_week7_cafe_event_journal(rabbit_name: String, journal_id: String, event_id: String, at: float) -> JournalEntry:
	var data := _load_json(WEEK7_CAFE_EVENTS_PATH)
	var events: Variant = data.get("events", {})
	if not (events is Dictionary) or not events.has(event_id):
		return null
	var template := _pick_dictionary(events[event_id])
	if template.is_empty():
		return null
	var journal := _base(journal_id, rabbit_name, "cafe_event", at, str(template.get("title", "咖啡館事件")), str(template.get("content", "")))
	journal.life_event_id = event_id
	journal.cafe_activity_id = event_id
	journal.building_id = "cafe"
	journal.is_special_memory = true
	journal.is_life_memory = true
	journal.is_village_memory = true
	return journal

static func generate_week7_growth_journal(rabbit_name: String, journal_id: String, event_id: String, growth_path: String, growth_stage: int, growth_mark_id: String, at: float) -> JournalEntry:
	var path := WEEK7_FOREST_STAGE3_PATH if event_id == "growth_forest_stage3_001" else WEEK7_LAKESIDE_STAGE2_PATH if event_id == "growth_lakeside_stage2_001" else ""
	if path.is_empty():
		return null
	var data := _load_json(path)
	var template := _pick_dictionary(data.get("templates", []))
	if template.is_empty():
		return null
	var journal := _base(journal_id, rabbit_name, "week7_growth", at, str(template.get("title", "新的成長")), str(template.get("content", "")))
	journal.growth_event_id = event_id
	journal.growth_mark_id = growth_mark_id
	journal.growth_path = growth_path
	journal.growth_stage = growth_stage
	journal.is_special_memory = true
	journal.is_life_memory = true
	journal.illustration_id = growth_mark_id
	return journal

static func generate_week7_growth_reaction_journal(rabbit_name: String, journal_id: String, source_record_id: String, growth_path: String, growth_stage: int, at: float) -> JournalEntry:
	if source_record_id.is_empty():
		return null
	var data := _load_json(WEEK7_GROWTH_REACTIONS_PATH)
	var template := _pick_dictionary(data.get("templates", []))
	if template.is_empty():
		return null
	var journal := _base(journal_id, rabbit_name, "growth_reaction", at, str(template.get("title", "新的樣子")), str(template.get("content", "")))
	journal.activity_record_id = source_record_id
	journal.growth_path = growth_path
	journal.growth_stage = growth_stage
	return journal

static func generate_week7_village_progress_journal(rabbit_name: String, journal_id: String, entry: VillageProgressHistoryEntry) -> JournalEntry:
	if entry == null or entry.village_progress_event_id.is_empty():
		return null
	var data := _load_json(WEEK7_VILLAGE_PROGRESS_PATH)
	var template := _pick_dictionary(data.get("templates", []))
	if template.is_empty():
		return null
	var journal := _base(journal_id, rabbit_name, "village_progress", entry.changed_at, str(template.get("title", "村莊進度")), str(template.get("content", "")))
	journal.village_progress_event_id = entry.village_progress_event_id
	journal.village_stage = entry.new_level
	return journal

static func generate_week7_finale_journal(rabbit_name: String, journal_id: String, event_id: String, at: float) -> JournalEntry:
	var data := _load_json(WEEK7_FINALE_PATH)
	var events: Variant = data.get("events", {})
	if not (events is Dictionary) or not events.has(event_id):
		return null
	var template := _pick_dictionary(events[event_id])
	if template.is_empty():
		return null
	var journal := _base(journal_id, rabbit_name, "week7_finale", at, str(template.get("title", "村莊第一次擴張")), str(template.get("content", "")))
	journal.life_event_id = event_id
	journal.village_progress_event_id = event_id
	journal.is_special_memory = true
	journal.is_life_memory = true
	journal.is_village_memory = true
	return journal

# ---------------- Week 8 ----------------

static func generate_week8_growth_direction_journal(rabbit_name: String, journal_id: String, choice: GrowthDirectionChoiceHistoryEntry) -> JournalEntry:
	if choice == null or choice.choice_id.is_empty():
		return null
	var data := _load_json(WEEK8_GROWTH_DIRECTION_PATH)
	var template := _pick_filtered(data.get("templates", []), "choice_id", choice.choice_id)
	if template.is_empty():
		return null
	var journal := _base(journal_id, rabbit_name, "growth_direction", choice.selected_at, str(template.get("title", "成長方向")), str(template.get("content", "")))
	journal.growth_direction_choice_id = choice.choice_id
	journal.growth_path = choice.resolved_branch
	journal.is_special_memory = true
	journal.is_life_memory = true
	return journal

static func generate_week8_balanced_journal(rabbit_name: String, journal_id: String, choice: GrowthDirectionChoiceHistoryEntry) -> JournalEntry:
	if choice == null or choice.choice_id.is_empty():
		return null
	var data := _load_json(WEEK8_BALANCED_PATH)
	var template := _pick_dictionary(data.get("templates", []))
	if template.is_empty():
		return null
	var journal := _base(journal_id, rabbit_name, "balanced", choice.selected_at, str(template.get("title", "現在的 Amy")), str(template.get("content", "")))
	journal.growth_direction_choice_id = choice.choice_id
	journal.final_form = "none"
	journal.growth_form = "none"
	journal.is_life_memory = true
	return journal

static func generate_week8_final_growth_journal(rabbit_name: String, journal_id: String, entry: FinalGrowthHistoryEntry) -> JournalEntry:
	if entry == null or entry.final_growth_record_id.is_empty():
		return null
	var path := WEEK8_FOREST_FINAL_PATH if entry.growth_path == "forest" else WEEK8_LAKESIDE_FINAL_PATH
	var data := _load_json(path)
	var template := _pick_filtered(data.get("templates", []), "form", entry.final_form)
	if template.is_empty():
		template = _pick_dictionary(data.get("templates", []))
	if template.is_empty():
		return null
	var journal := _base(journal_id, rabbit_name, "final_growth", entry.completed_at, str(template.get("title", "Amy 長大了")), str(template.get("content", "")))
	journal.final_growth_record_id = entry.final_growth_record_id
	journal.final_form = entry.final_form
	journal.growth_form = entry.final_form
	journal.growth_path = entry.growth_path
	journal.growth_stage = entry.new_stage
	journal.is_special_memory = true
	journal.is_life_memory = true
	return journal

static func generate_week8_final_reaction_journal(rabbit_name: String, journal_id: String, source_record_id: String, context: String, final_form: String, at: float, post_ending := false) -> JournalEntry:
	if source_record_id.is_empty():
		return null
	var path := ""
	match context:
		"home": path = WEEK8_FINAL_HOME_PATH
		"forest": path = WEEK8_FINAL_FOREST_PATH
		"lake", "lakeside": path = WEEK8_FINAL_LAKESIDE_PATH
		"cafe": path = WEEK8_FINAL_CAFE_PATH
		"picnic": path = WEEK8_FINAL_PICNIC_PATH
	if path.is_empty():
		return null
	var data := _load_json(path)
	var template := _pick_filtered(data.get("templates", []), "form", final_form)
	if template.is_empty():
		return null
	var journal := _base(journal_id, rabbit_name, "final_reaction", at, str(template.get("title", "成長後的日常")), str(template.get("content", "")))
	journal.final_form = final_form
	journal.growth_form = final_form
	if context == "picnic":
		journal.life_location_id = source_record_id
		journal.life_location_activity_id = "picnic"
		journal.location_id = "picnic_area"
		journal.location_name = "野餐區"
	else:
		journal.activity_record_id = source_record_id
		journal.location_id = "lake" if context in ["lake", "lakeside"] else context
		journal.location_name = {"home": "家裡", "forest": "森林", "lake": "湖邊", "lakeside": "湖邊", "cafe": "咖啡館"}.get(context, "村莊")
	journal.is_post_ending = post_ending
	return journal

static func generate_week8_stage1_journal(rabbit_name: String, journal_id: String, entry: StageCompletionHistoryEntry) -> JournalEntry:
	if entry == null:
		return null
	var data := _load_json(WEEK8_VILLAGE_STAGE1_PATH)
	var template := _pick_dictionary(data.get("templates", []))
	if template.is_empty(): return null
	var journal := _base(journal_id, rabbit_name, "village_stage1", entry.completed_at, str(template.get("title", "這裡真的變成一個村子了")), str(template.get("content", "")))
	journal.village_progress_event_id = entry.source_event_id
	journal.village_stage = 1
	journal.is_special_memory = true
	journal.is_village_memory = true
	journal.is_life_memory = true
	return journal

static func generate_week8_life_resume_journal(rabbit_name: String, journal_id: String, profile_snapshot_id: String, at: float) -> JournalEntry:
	if profile_snapshot_id.is_empty(): return null
	var data := _load_json(WEEK8_LIFE_RESUME_PATH)
	var template := _pick_dictionary(data.get("templates", []))
	if template.is_empty(): return null
	var journal := _base(journal_id, rabbit_name, "life_resume", at, str(template.get("title", "Amy 的生活履歷")), str(template.get("content", "")))
	journal.life_profile_snapshot_id = profile_snapshot_id
	journal.is_life_memory = true
	return journal

static func generate_week8_ending_journal(rabbit_name: String, journal_id: String, entry: EndingHistoryEntry) -> JournalEntry:
	if entry == null or entry.ending_id.is_empty(): return null
	var data := _load_json(WEEK8_ENDING_PATH)
	var template := _pick_filtered(data.get("templates", []), "ending_type", entry.ending_type)
	if template.is_empty(): template = _pick_dictionary(data.get("templates", []))
	if template.is_empty(): return null
	var journal := _base(journal_id, rabbit_name, "ending", entry.completed_at, str(template.get("title", "第一階段 Ending")), str(template.get("content", "")))
	journal.ending_id = entry.ending_id
	journal.ending_snapshot_id = entry.snapshot_id
	journal.final_form = entry.final_form
	journal.growth_form = entry.final_form
	journal.is_special_memory = true
	journal.is_life_memory = true
	journal.is_village_memory = true
	return journal

static func generate_week8_post_ending_journal(rabbit_name: String, journal_id: String, source_record_id: String, final_form: String, at: float, context: String = "") -> JournalEntry:
	if source_record_id.is_empty(): return null
	var data := _load_json(WEEK8_POST_ENDING_PATH)
	var template := _pick_filtered(data.get("templates", []), "form", final_form)
	if template.is_empty(): template = _pick_dictionary(data.get("templates", []))
	if template.is_empty(): return null
	var journal := _base(journal_id, rabbit_name, "post_ending", at, str(template.get("title", "Ending 之後的日常")), str(template.get("content", "")))
	journal.activity_record_id = source_record_id
	journal.final_form = final_form
	journal.growth_form = final_form
	journal.is_post_ending = true
	journal.location_id = "lake" if context in ["lake", "lakeside"] else context
	journal.location_name = {"home": "家裡", "forest": "森林", "lake": "湖邊", "lakeside": "湖邊", "cafe": "咖啡館", "picnic": "野餐區"}.get(context, "村莊")
	return journal

# ---------------- Week 9 ----------------

static func generate_week9_resident_arrival_journal(rabbit_name: String, journal_id: String, entry: ResidentHistoryEntry, relationship_state := ResidentRelationshipData.STRANGER) -> JournalEntry:
	if entry == null or entry.resident_id.is_empty():
		return null
	var template := _pick_dictionary(_load_json(RESIDENT_CAFE_OWNER_PATH).get("templates", []))
	if template.is_empty():
		return null
	var journal := _base(journal_id, rabbit_name, "resident_arrival", entry.created_at, str(template.get("title", "新的居民")), str(template.get("content", "{rabbit_name} 注意到村莊裡多了一位居民。")))
	journal.resident_id = entry.resident_id
	journal.relationship_state = relationship_state
	journal.resident_event_id = entry.source_event_id if not entry.source_event_id.is_empty() else entry.history_id
	journal.location_id = entry.location_id
	journal.location_name = _resident_location_name(entry.location_id)
	journal.is_special_memory = true
	journal.is_life_memory = true
	return journal

static func generate_week9_first_meeting_journal(rabbit_name: String, journal_id: String, entry: ResidentHistoryEntry, relationship_state := ResidentRelationshipData.STRANGER) -> JournalEntry:
	if entry == null or entry.resident_id.is_empty():
		return null
	var template := _pick_dictionary(_load_json(RESIDENT_FIRST_MEETING_PATH).get("templates", []))
	if template.is_empty():
		return null
	var journal := _base(journal_id, rabbit_name, "resident_first_meeting", entry.created_at, str(template.get("title", "第一次正式認識")), str(template.get("content", "{rabbit_name} 第一次和居民正式認識。")))
	journal.resident_id = entry.resident_id
	journal.relationship_state = relationship_state
	journal.resident_interaction_id = entry.source_event_id
	journal.resident_event_id = entry.history_id
	journal.location_id = entry.location_id
	journal.location_name = _resident_location_name(entry.location_id)
	journal.is_special_memory = true
	journal.is_life_memory = true
	return journal

static func generate_week9_interaction_journal(rabbit_name: String, journal_id: String, entry: ResidentInteractionHistoryEntry) -> JournalEntry:
	if entry == null or entry.interaction_id.is_empty() or entry.resident_id.is_empty():
		return null
	var path := _resident_reaction_path(entry.reaction_tag)
	if path.is_empty():
		path = RESIDENT_CONVERSATION_PATH
	var template := _pick_dictionary(_load_json(path).get("templates", []))
	if template.is_empty():
		return null
	var journal := _base(journal_id, rabbit_name, "resident_interaction", entry.interacted_at, str(template.get("title", "聊了一會兒")), str(template.get("content", "{rabbit_name} 和居民聊了一會兒。")))
	journal.resident_id = entry.resident_id
	journal.relationship_state = entry.relationship_state
	journal.resident_interaction_id = entry.interaction_id
	journal.activity_record_id = entry.interaction_id
	journal.activity_id = entry.interaction_type
	journal.growth_form = _resident_branch_from_reaction(entry.reaction_tag)
	journal.stat_changes = {"relationship": entry.relationship_change, "social_experience": entry.social_experience_change}
	return journal

static func generate_week9_shared_activity_journal(rabbit_name: String, journal_id: String, entry: SharedActivityHistoryEntry) -> JournalEntry:
	if entry == null or entry.activity_record_id.is_empty() or entry.resident_id.is_empty():
		return null
	var path := RESIDENT_SHARED_CAFE_PATH
	var location := entry.location_id
	if location in ["forest"] or entry.activity_id.contains("forest"):
		path = RESIDENT_SHARED_FOREST_PATH
	elif location in ["picnic"] or entry.activity_id.contains("picnic"):
		path = RESIDENT_SHARED_PICNIC_PATH
	var template := _pick_dictionary(_load_json(path).get("templates", []))
	if template.is_empty():
		return null
	var journal := _base(journal_id, rabbit_name, "resident_shared_activity", entry.completed_at, str(template.get("title", "一起活動")), str(template.get("content", "{rabbit_name} 和居民一起度過了一段時間。")))
	journal.resident_id = entry.resident_id
	journal.relationship_state = entry.relationship_state
	journal.shared_activity_id = entry.activity_record_id
	journal.activity_record_id = entry.activity_record_id
	journal.activity_id = entry.activity_id
	journal.location_id = location
	journal.location_name = _resident_location_name(location)
	journal.growth_form = _resident_branch_from_reaction(entry.reaction_tag)
	journal.stat_changes = {"relationship": entry.relationship_change, "social_experience": entry.social_experience_change}
	return journal

static func generate_week9_visit_journal(rabbit_name: String, journal_id: String, entry: ResidentVisitHistoryEntry, relationship_state := "") -> JournalEntry:
	if entry == null or entry.event_id.is_empty():
		return null
	var template := _pick_dictionary(_load_json(RESIDENT_HOME_VISIT_PATH).get("templates", []))
	if template.is_empty():
		return null
	var journal := _base(journal_id, rabbit_name, "resident_visit", entry.visited_at, str(template.get("title", "居民拜訪")), str(template.get("content", "今天有居民來找{rabbit_name}。")))
	journal.resident_id = entry.resident_id
	journal.relationship_state = relationship_state
	journal.resident_event_id = entry.event_id
	journal.life_event_id = entry.event_id
	journal.location_id = entry.location_id
	journal.location_name = _resident_location_name(entry.location_id)
	journal.is_special_memory = true
	return journal

static func generate_week9_gift_journal(rabbit_name: String, journal_id: String, entry: ResidentGiftHistoryEntry, relationship_state := "") -> JournalEntry:
	if entry == null or entry.event_id.is_empty():
		return null
	var template := _pick_dictionary(_load_json(RESIDENT_GIFT_PATH).get("templates", []))
	if template.is_empty():
		return null
	var journal := _base(journal_id, rabbit_name, "resident_gift", entry.received_at, str(template.get("title", "收到居民禮物")), str(template.get("content", "{rabbit_name} 收到居民送的禮物。")))
	journal.resident_id = entry.resident_id
	journal.relationship_state = relationship_state
	journal.resident_event_id = entry.event_id
	journal.life_event_id = entry.event_id
	journal.item_id = entry.item_id
	journal.items = ["%s:%d" % [entry.item_id, entry.amount]]
	journal.is_special_memory = true
	journal.is_life_memory = true
	return journal

static func generate_week9_letter_journal(rabbit_name: String, journal_id: String, entry: ResidentLetterHistoryEntry, relationship_state := "") -> JournalEntry:
	if entry == null or entry.event_id.is_empty():
		return null
	var template := _pick_dictionary(_load_json(RESIDENT_LETTER_PATH).get("templates", []))
	if template.is_empty():
		return null
	var journal := _base(journal_id, rabbit_name, "resident_letter", entry.received_at, str(template.get("title", "收到一封信")), str(template.get("content", "{rabbit_name} 收到居民寄來的信。")))
	journal.resident_id = entry.resident_id
	journal.relationship_state = relationship_state
	journal.resident_event_id = entry.event_id
	journal.life_event_id = entry.event_id
	journal.growth_form = _resident_branch_from_reaction(entry.reaction_tag)
	return journal

static func generate_week9_invitation_journal(rabbit_name: String, journal_id: String, entry: ResidentInvitationHistoryEntry, relationship_state := "") -> JournalEntry:
	if entry == null or entry.invitation_id.is_empty():
		return null
	var template := _pick_dictionary(_load_json(RESIDENT_INVITATION_PATH).get("templates", []))
	if template.is_empty():
		return null
	var content := str(template.get("content", "{rabbit_name} 收到居民的邀請。"))
	if entry.state == "accepted":
		content += " 最後，{rabbit_name}答應了這個邀請。"
	elif entry.state == "declined":
		content += " 最後，{rabbit_name}這次沒有答應，但關係沒有因此變差。"
	var journal := _base(journal_id, rabbit_name, "resident_invitation", entry.responded_at if entry.responded_at > 0.0 else entry.created_at, str(template.get("title", "收到居民邀請")), content)
	journal.resident_id = entry.resident_id
	journal.relationship_state = relationship_state
	journal.invitation_id = entry.invitation_id
	journal.shared_activity_id = entry.activity_id
	journal.activity_id = entry.activity_id
	return journal

static func generate_week9_first_friend_journal(rabbit_name: String, journal_id: String, entry: ResidentRelationshipHistoryEntry) -> JournalEntry:
	if entry == null or entry.resident_id.is_empty() or entry.new_state != ResidentRelationshipData.FRIEND:
		return null
	var template := _pick_dictionary(_load_json(RESIDENT_FIRST_FRIEND_PATH).get("templates", []))
	if template.is_empty():
		return null
	var journal := _base(journal_id, rabbit_name, "resident_first_friend", entry.stage_changed_at, str(template.get("title", "第一位朋友")), str(template.get("content", "{rabbit_name} 在村莊裡有了第一位朋友。")))
	journal.resident_id = entry.resident_id
	journal.relationship_state = entry.new_state
	journal.resident_event_id = entry.relationship_history_id
	journal.resident_interaction_id = entry.source_id
	journal.is_special_memory = true
	journal.is_life_memory = true
	return journal

static func _resident_reaction_path(reaction_tag: String) -> String:
	var branch := _resident_branch_from_reaction(reaction_tag)
	match branch:
		"forest": return RESIDENT_FOREST_REACTION_PATH
		"lakeside": return RESIDENT_LAKESIDE_REACTION_PATH
		"balanced": return RESIDENT_BALANCED_REACTION_PATH
	return RESIDENT_CONVERSATION_PATH

static func _resident_branch_from_reaction(reaction_tag: String) -> String:
	if reaction_tag.contains("_forest_"):
		return "forest"
	if reaction_tag.contains("_lakeside_"):
		return "lakeside"
	if reaction_tag.contains("_balanced_"):
		return "balanced"
	return ""

static func _resident_location_name(location_id: String) -> String:
	return {"home": "家裡", "forest": "森林", "lake": "湖邊", "lakeside": "湖邊", "cafe": "咖啡館", "picnic": "野餐區"}.get(location_id, "村莊")

static func _base(id: String, rabbit_name: String, journal_type: String, at: float, title: String, content: String) -> JournalEntry:
	var time := TimeManager.get_now() if at <= 0.0 else at
	return JournalEntry.new(id, "", _format_date(time), "", rabbit_name, title, _format_content(content, rabbit_name), time, journal_type, "village", "村莊")

static func _pick_activity_template(activity_id: String) -> Dictionary:
	var path := str(TEMPLATE_PATHS.get(activity_id, ""))
	if path.is_empty():
		return {}
	var data := _load_json(path)
	return _pick_dictionary(data.get("templates", []))

static func _pick_filtered(raw: Variant, key: String, expected: Variant) -> Dictionary:
	if not (raw is Array):
		return {}
	var matches: Array[Dictionary] = []
	for item: Variant in raw:
		if item is Dictionary and item.get(key, null) == expected:
			matches.append(item)
	return _pick_dictionary(matches)

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

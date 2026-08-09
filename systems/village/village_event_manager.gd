class_name VillageEventManager
extends Node

signal village_event_created(event: VillageEventData)
signal village_event_completed(result: VillageEventResult)
var data: VillageData
var rabbit: RabbitData
var buildings: BuildingManager
var growth: GrowthManager
var events: Dictionary = {}

func _init() -> void:
	_register("village_notice_board_001", "村莊的新消息", "公告欄可以開始施工了。", 1, 2, "notice_board")
	_register("village_carrot_farm_001", "第一塊農地", "小農田可以開始施工了。", 2, 4, "carrot_farm", "rest_pavilion", 1)
	_register("village_growing_001", "成長中的村莊", "Amy 和村莊一起成長。", 3, 8, "", "carrot_farm", 0)
func _register(id: String, title: String, desc: String, level: int, activities: int, unlock: String, required_building := "", uses := 0) -> void:
	var e := VillageEventData.new(); e.event_id = id; e.title = title; e.description = desc; e.required_village_level = level; e.required_total_activity_count = activities; e.unlock_building_id = unlock; e.required_building_id = required_building; e.required_building_use_count = uses; events[id] = e
func setup(village_data: VillageData, rabbit_data: RabbitData, building_manager: BuildingManager, growth_manager: GrowthManager) -> void: data = village_data; rabbit = rabbit_data; buildings = building_manager; growth = growth_manager
func check_event_conditions() -> VillageEventData:
	if has_pending_event() or (growth != null and growth.has_pending_growth_event()): return null
	for event: VillageEventData in events.values():
		if can_trigger_event(event.event_id): return create_pending_event(event.event_id)
	return null
func can_trigger_event(id: String) -> bool:
	if not events.has(id) or has_completed_event(id) or has_pending_event(): return false
	var e: VillageEventData = events[id]
	if data.progress.village_level < e.required_village_level or rabbit.total_activity_count < e.required_total_activity_count: return false
	if rabbit.forest_activity_count < e.required_forest_activity_count or rabbit.fishing_activity_count < e.required_fishing_activity_count or rabbit.home_activity_count < e.required_home_activity_count: return false
	if not e.required_building_id.is_empty():
		if not buildings.is_building_completed(e.required_building_id): return false
		var record: Dictionary = data.building_records.get(e.required_building_id, {})
		if int(record.get("use_count", 0)) < e.required_building_use_count: return false
	return true
func create_pending_event(id: String) -> VillageEventData:
	if not can_trigger_event(id): return null
	var event: VillageEventData = events[id]; event.triggered_at = TimeManager.get_now(); event.state = VillageEventState.PENDING
	data.pending_village_events = [event.to_dict()]; village_event_created.emit(event); return event
func has_pending_event() -> bool: return data != null and not data.pending_village_events.is_empty()
func get_pending_event() -> VillageEventData: return VillageEventData.from_dict(data.pending_village_events[0]) if has_pending_event() else null
func confirm_event(id: String) -> VillageEventResult:
	var event := get_pending_event()
	if event == null or event.event_id != id or event.is_applied or has_completed_event(id): return null
	return apply_event_result(id)
func apply_event_result(id: String) -> VillageEventResult:
	var event := get_pending_event()
	if event == null or event.event_id != id: return null
	event.confirmed_at = TimeManager.get_now(); event.state = VillageEventState.COMPLETED; event.is_applied = true
	if not event.unlock_building_id.is_empty(): buildings.unlock_building(event.unlock_building_id)
	data.completed_village_event_ids.append(id); data.progress.completed_village_event_count += 1; data.pending_village_events.clear()
	var result := VillageEventResult.new(); result.event_id = id; result.unlocked_building_id = event.unlock_building_id; result.applied_at = event.confirmed_at; village_event_completed.emit(result); return result
func has_completed_event(id: String) -> bool: return data != null and data.completed_village_event_ids.has(id)
func get_completed_events() -> Array[VillageEventData]:
	var out: Array[VillageEventData] = []
	for id in data.completed_village_event_ids:
		if events.has(id): out.append(events[id])
	return out
func CheckEventConditions() -> VillageEventData: return check_event_conditions()
func CanTriggerEvent(id: String) -> bool: return can_trigger_event(id)
func CreatePendingEvent(id: String) -> VillageEventData: return create_pending_event(id)
func HasPendingEvent() -> bool: return has_pending_event()
func GetPendingEvent() -> VillageEventData: return get_pending_event()
func ConfirmEvent(id: String) -> VillageEventResult: return confirm_event(id)
func ApplyEventResult(id: String) -> VillageEventResult: return apply_event_result(id)
func HasCompletedEvent(id: String) -> bool: return has_completed_event(id)
func GetCompletedEvents() -> Array[VillageEventData]: return get_completed_events()

class_name NoticeManager
extends Node

signal notice_generated(notice: DailyNoticeData)
signal notice_read(notice: DailyNoticeData)
var data: VillageData
var village: VillageManager
var buildings: BuildingManager
var construction: ConstructionManager
var farm: FarmManager
var growth: GrowthManager
var recent_activity_location := ""
func setup(village_data: VillageData, village_manager: VillageManager, building_manager: BuildingManager, construction_manager: ConstructionManager, farm_manager: FarmManager, growth_manager: GrowthManager) -> void: data = village_data; village = village_manager; buildings = building_manager; construction = construction_manager; farm = farm_manager; growth = growth_manager
func _date_key() -> String: var d := Time.get_date_dict_from_system(); return "%04d-%02d-%02d" % [d.year, d.month, d.day]
func has_today_notice() -> bool: return get_today_notice() != null
func get_today_notice() -> DailyNoticeData:
	for raw: Dictionary in data.notices:
		if raw.get("date_key") == _date_key(): return DailyNoticeData.from_dict(raw)
	return null
func generate_today_notice() -> DailyNoticeData:
	var existing := get_today_notice(); if existing: return existing
	var notice := DailyNoticeData.new(); notice.notice_id = "notice_" + _date_key(); notice.date_key = _date_key(); notice.generated_at = TimeManager.get_now(); notice.content = "今天的村莊也很平靜。"
	data.notices.append(notice.to_dict()); notice_generated.emit(notice); return notice
func mark_today_notice_read() -> bool:
	if not buildings.is_building_completed("notice_board"): return false
	var notice := get_today_notice()
	if notice == null: notice = generate_today_notice()
	if notice.is_read: return false
	notice.is_read = true; notice.first_read_at = TimeManager.get_now()
	for i in data.notices.size():
		if data.notices[i].get("notice_id") == notice.notice_id: data.notices[i] = notice.to_dict(); break
	village.register_notice_read(); village.claim_reward_once("notice_read:" + notice.date_key, 5); notice_read.emit(notice); return true
func has_read_today_notice() -> bool: var n := get_today_notice(); return n != null and n.is_read
func get_notice_condition_context() -> Dictionary:
	var c := NoticeConditionData.new(); c.recent_activity_location = recent_activity_location; c.constructing_building_id = construction.get_active_construction().building_id if construction.has_active_construction() else ""; c.is_farm_growing = farm.has_active_growth_cycle(); c.are_carrots_ready = farm.is_farm_ready(); c.has_leaf_mark = growth.has_growth_mark("leaf_mark")
	for r in buildings.get_completed_buildings(): c.completed_building_ids.append(r.building_id)
	return c.to_dict()
func get_notice_history() -> Array[Dictionary]: return data.notices.duplicate(true)
func HasTodayNotice() -> bool: return has_today_notice()
func GetTodayNotice() -> DailyNoticeData: return get_today_notice()
func GenerateTodayNotice() -> DailyNoticeData: return generate_today_notice()
func MarkTodayNoticeRead() -> bool: return mark_today_notice_read()
func HasReadTodayNotice() -> bool: return has_read_today_notice()
func GetNoticeConditionContext() -> Dictionary: return get_notice_condition_context()
func GetNoticeHistory() -> Array[Dictionary]: return get_notice_history()

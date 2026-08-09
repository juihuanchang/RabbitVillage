class_name VillageProgressData
extends Resource

@export var village_level := 1
@export var village_experience := 0
@export var completed_building_count := 0
@export var completed_village_event_count := 0
@export var rest_pavilion_use_count := 0
@export var notice_board_read_count := 0
@export var farm_growth_cycle_count := 0
@export var total_harvest_count := 0
@export var total_carrots_obtained := 0

func to_dict() -> Dictionary:
	return {"village_level": village_level, "village_experience": village_experience,
		"completed_building_count": completed_building_count,
		"completed_village_event_count": completed_village_event_count,
		"rest_pavilion_use_count": rest_pavilion_use_count,
		"notice_board_read_count": notice_board_read_count,
		"farm_growth_cycle_count": farm_growth_cycle_count,
		"total_harvest_count": total_harvest_count,
		"total_carrots_obtained": total_carrots_obtained}

static func from_dict(data: Dictionary) -> VillageProgressData:
	var p := VillageProgressData.new()
	p.village_level = maxi(1, int(data.get("village_level", 1)))
	p.village_experience = maxi(0, int(data.get("village_experience", 0)))
	p.completed_building_count = maxi(0, int(data.get("completed_building_count", 0)))
	p.completed_village_event_count = maxi(0, int(data.get("completed_village_event_count", 0)))
	p.rest_pavilion_use_count = maxi(0, int(data.get("rest_pavilion_use_count", 0)))
	p.notice_board_read_count = maxi(0, int(data.get("notice_board_read_count", 0)))
	p.farm_growth_cycle_count = maxi(0, int(data.get("farm_growth_cycle_count", 0)))
	p.total_harvest_count = maxi(0, int(data.get("total_harvest_count", 0)))
	p.total_carrots_obtained = maxi(0, int(data.get("total_carrots_obtained", 0)))
	return p

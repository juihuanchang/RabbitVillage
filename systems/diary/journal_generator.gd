class_name JournalGenerator
extends RefCounted

const TEMPLATE_PATHS := {"forest_walk":"res://data/journals/forest_walk.json","forest_explore":"res://data/journals/forest_explore.json","fishing":"res://data/journals/fishing.json","home_rest":"res://data/journals/home_rest.json"}
const LEAF_MARK_PATH := "res://data/journals/leaf_mark.json"
const VILLAGE_EVENT_PATH := "res://data/journals/week4/village_events.json"
const CONSTRUCTION_PATH := "res://data/journals/week4/construction.json"
const REST_PAVILION_PATH := "res://data/journals/week4/rest_pavilion.json"
const FARM_PATH := "res://data/journals/week4/farm.json"
const HARVEST_PATH := "res://data/journals/week4/harvest.json"

static func generate(active: ActiveActivityData, journal_id: String) -> JournalEntry:
    if active == null or active.rabbit == null or active.activity == null: return null
    var t := _pick_activity_template(active.activity.activity_id)
    var at := active.completed_at if active.completed_at > 0.0 else TimeManager.get_now()
    return JournalEntry.new(journal_id, active.activity_record_id, _format_date(at), active.activity.activity_id, active.rabbit.rabbit_name,
        str(t.get("title", "%s完成" % active.activity.activity_name)), str(t.get("content", "{rabbit_name} 完成了%s。" % active.activity.activity_name)).replace("{rabbit_name}",active.rabbit.rabbit_name), at,
        "home" if active.activity.activity_id == "home_rest" else "activity", active.activity.location_id, active.activity.location_name, active.get_stat_changes(), active.activity.reward_items)
static func generate_growth_journal(rabbit_name: String, journal_id: String, mark_id: String, created_at: float = -1.0) -> JournalEntry:
    if mark_id != "leaf_mark": return null
    var d := _load_json(LEAF_MARK_PATH); if d.is_empty(): return null
    var at := TimeManager.get_now() if created_at <= 0.0 else created_at
    return JournalEntry.new(journal_id,"",_format_date(at),"",rabbit_name,str(d.get("title","耳朵旁的小葉子")),str(d.get("content","")).replace("{rabbit_name}",rabbit_name),at,"growth",str(d.get("location_id","forest")),str(d.get("location_name","森林")),{},[],mark_id,false,false,true,str(d.get("illustration_id","leaf_mark_memory")))
static func generate_village_event_journal(rabbit_name: String, journal_id: String, event_id: String, at: float, stage: int) -> JournalEntry:
    var d := _load_json(VILLAGE_EVENT_PATH); var all: Variant = d.get("templates",{})
    if not (all is Dictionary) or not all.has(event_id): return null
    var t: Dictionary = all[event_id]; var e := _base(journal_id,rabbit_name,"village_event",at,str(t.get("title","村莊事件")),str(t.get("content","")))
    e.village_event_id=event_id; e.village_stage=stage; e.is_village_memory=true; return e
static func generate_construction_journal(rabbit_name: String, journal_id: String, record_id: String, building_id: String, phase: String, at: float, stage: int) -> JournalEntry:
    var d:=_load_json(CONSTRUCTION_PATH); var all: Variant=d.get("templates",{})
    if not (all is Dictionary) or not all.has(building_id): return null
    var bt: Variant=all[building_id]; if not (bt is Dictionary) or not bt.has(phase): return null
    var t: Dictionary=bt[phase]; var typ := "construction" if phase=="start" else "building_complete"
    var e:=_base(journal_id,rabbit_name,typ,at,str(t.get("title","建築紀錄")),str(t.get("content",""))); e.building_id=building_id; e.construction_record_id=record_id; e.village_stage=stage; e.is_village_memory=typ=="building_complete"; return e
static func generate_building_use_journal(rabbit_name: String, journal_id: String, result: BuildingUseResult, first: bool, stage: int) -> JournalEntry:
    if result==null or result.building_id!="rest_pavilion": return null
    var d:=_load_json(REST_PAVILION_PATH); var t: Dictionary={}
    if first:
        if d.get("first_use",{}) is Dictionary: t=d.get("first_use",{})
    else:
        var arr: Variant=d.get("general",[])
        if arr is Array and not arr.is_empty():
            var raw: Variant=arr.pick_random(); if raw is Dictionary: t=raw
    if t.is_empty(): return null
    var e:=_base(journal_id,rabbit_name,"building_use",result.completed_at,str(t.get("title","休息亭時光")),str(t.get("content","")))
    e.building_id=result.building_id; e.building_use_record_id=result.building_use_record_id if not result.building_use_record_id.is_empty() else result.interaction_record_id; e.village_stage=stage
    e.stat_changes={"energy":result.energy_change,"mood":result.mood_change,"intimacy":result.intimacy_change}; e.is_special_memory=first; e.is_village_memory=first; return e
static func generate_notice_journal(rabbit_name: String, journal_id: String, notice: DailyNoticeRecord, stage: int) -> JournalEntry:
    if notice==null: return null
    var at:=notice.first_read_at if notice.first_read_at>0.0 else notice.generated_at; var e:=_base(journal_id,rabbit_name,"notice",at,"今天的村莊公告",notice.content); e.notice_id=notice.notice_id; e.notice_date=notice.date_key; e.village_stage=stage; return e
static func generate_farm_growth_journal(rabbit_name: String, journal_id: String, cycle: FarmCycleData, first: bool, stage: int) -> JournalEntry:
    if cycle==null: return null
    var d:=_load_json(FARM_PATH); var t: Dictionary={}
    if first and d.get("first_growth",{}) is Dictionary: t=d.get("first_growth",{})
    else:
        var arr: Variant=d.get("growth",[])
        if arr is Array and not arr.is_empty() and arr[0] is Dictionary: t=arr[0]
    if t.is_empty(): return null
    var e:=_base(journal_id,rabbit_name,"farm_growth",cycle.started_at,str(t.get("title","胡蘿蔔開始生長")),str(t.get("content",""))); e.building_id="carrot_farm"; e.farm_cycle_id=cycle.farm_cycle_id; e.village_stage=stage; e.is_village_memory=first; return e
static func generate_harvest_journal(rabbit_name: String, journal_id: String, result: HarvestResult, first: bool, stage: int) -> JournalEntry:
    if result==null: return null
    var d:=_load_json(HARVEST_PATH); var t: Dictionary={}
    if first and d.get("first_harvest",{}) is Dictionary: t=d.get("first_harvest",{})
    else:
        var arr: Variant=d.get("general",[])
        if arr is Array and not arr.is_empty():
            var raw: Variant=arr.pick_random(); if raw is Dictionary: t=raw
    if t.is_empty(): return null
    var e:=_base(journal_id,rabbit_name,"harvest",result.harvested_at,str(t.get("title","胡蘿蔔收成")),str(t.get("content",""))); e.building_id="carrot_farm"; e.farm_cycle_id=result.farm_cycle_id; e.harvest_record_id=result.harvest_record_id; e.village_stage=stage; e.items=["carrot:%d"%maxi(0,result.amount)]; e.is_special_memory=first; e.is_village_memory=first; return e
static func generate_village_growth_journal(rabbit_name: String, journal_id: String, stage: int, at: float) -> JournalEntry:
    if stage<=0: return null
    var e:=_base(journal_id,rabbit_name,"village_growth",at,"村莊又長大了一點","Amy 發現村莊和以前不太一樣了。新的角落、建築和故事，正在慢慢把這裡變成真正的家。"); e.village_stage=stage; e.is_village_memory=true; return e
static func _base(id:String,rabbit_name:String,typ:String,at:float,title:String,content:String)->JournalEntry:
    var time:=TimeManager.get_now() if at<=0.0 else at; return JournalEntry.new(id,"",_format_date(time),"",rabbit_name,title,content.replace("{rabbit_name}",rabbit_name),time,typ,"village","村莊")
static func _pick_activity_template(id:String)->Dictionary:
    var path:=str(TEMPLATE_PATHS.get(id,"")); if path.is_empty(): return {}
    var d:=_load_json(path); var arr: Variant=d.get("templates",[]); if not (arr is Array) or arr.is_empty(): return {}
    var raw: Variant=arr.pick_random(); return raw.duplicate(true) if raw is Dictionary else {}
static func _load_json(path:String)->Dictionary:
    if not FileAccess.file_exists(path): return {}
    var j:=JSON.new(); if j.parse(FileAccess.get_file_as_string(path))!=OK or not (j.data is Dictionary): return {}
    return j.data
static func _format_date(t:float)->String:
    var d:=TimeManager.get_local_datetime(t); return "%04d/%02d/%02d"%[d.year,d.month,d.day]

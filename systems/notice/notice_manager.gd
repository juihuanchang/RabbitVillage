class_name NoticeManager
extends Node
signal notice_generated(notice: DailyNoticeRecord)
signal notice_read(notice: DailyNoticeRecord)
const TEMPLATE_PATH := "res://data/notices/notice_templates.json"
var data:VillageData
var village:VillageManager
var buildings:BuildingManager
var construction:ConstructionManager
var farm:FarmManager
var growth:GrowthManager
var recent_activity_location:=""
var _templates:Array[NoticeTemplate]=[]
func setup(v:VillageData,vm:VillageManager,bm:BuildingManager,cm:ConstructionManager,fm:FarmManager,gm:GrowthManager)->void:
    data=v; village=vm; buildings=bm; construction=cm; farm=fm; growth=gm; _load_templates(); _repair_history(); _repair_today()
func _date_key(offset:=0)->String:
    var d:=TimeManager.get_local_datetime(TimeManager.get_now()+offset*86400); return "%04d-%02d-%02d"%[d.year,d.month,d.day]
func has_today_notice()->bool: return get_today_notice()!=null
func get_today_notice()->DailyNoticeRecord:
    if data==null: return null
    var today:=_date_key()
    if not data.daily_notice.is_empty():
        var n:=DailyNoticeRecord.from_dict(data.daily_notice)
        if n.is_valid_for_date(today): return n
    for raw in data.notice_history:
        if str(raw.get("date_key",""))==today:
            var n:=DailyNoticeRecord.from_dict(raw)
            if n.is_valid_for_date(today): data.daily_notice=n.to_dict(); return n
    return null
func generate_today_notice()->DailyNoticeRecord:
    var existing:=get_today_notice(); if existing!=null: return existing
    var t:=select_notice_template(NoticeConditionData.from_dict(get_notice_condition_context()))
    if t==null: t=_fallback_general(_previous_notice_id())
    if t==null: return null
    var n:=DailyNoticeRecord.new(); n.notice_id=t.notice_id; n.category=t.category; n.date_key=_date_key(); n.generated_at=TimeManager.get_now(); n.title="村莊公告"; n.content=t.content
    save_today_notice(n); notice_generated.emit(n); return n
func save_today_notice(n:DailyNoticeRecord)->bool:
    if data==null or n==null or n.notice_id.is_empty() or n.date_key.is_empty() or n.content.is_empty(): return false
    for i in data.notice_history.size():
        if str(data.notice_history[i].get("date_key",""))==n.date_key:
            data.notice_history[i]=n.to_dict()
            if n.date_key==_date_key(): data.daily_notice=n.to_dict()
            return true
    data.notice_history.append(n.to_dict())
    if n.date_key==_date_key(): data.daily_notice=n.to_dict()
    return true
func mark_today_notice_read()->bool:
    if not buildings.is_building_completed("notice_board"): return false
    var n:=get_today_notice(); if n==null: n=generate_today_notice()
    if n==null or n.is_read: return false
    n.is_read=true; n.first_read_at=TimeManager.get_now(); save_today_notice(n); village.register_notice_read(); village.claim_reward_once("notice_read:"+n.date_key,5); notice_read.emit(n); return true
func select_notice_template(c:NoticeConditionData)->NoticeTemplate:
    if _templates.is_empty(): _load_templates()
    var candidates:Array[NoticeTemplate]=[]; var previous:=_previous_notice_id()
    for t in _templates:
        if not _matches(t,c): continue
        if not t.can_repeat and _has_notice_id(t.notice_id): continue
        if t.notice_id==previous and _has_alternative(c,previous): continue
        candidates.append(t)
    if candidates.is_empty(): return _fallback_general(previous)
    var highest:=-999999
    for t in candidates: highest=maxi(highest,t.priority)
    var top:Array[NoticeTemplate]=[]
    for t in candidates:
        if t.priority==highest: top.append(t)
    return top.pick_random() if not top.is_empty() else candidates.pick_random()
func get_notice_condition_context()->Dictionary:
    var c:=NoticeConditionData.new(); c.recent_activity_location=recent_activity_location; c.constructing_building_id=construction.get_active_construction().building_id if construction.has_active_construction() else ""; c.is_farm_growing=farm.has_active_growth_cycle(); c.are_carrots_ready=farm.is_farm_ready(); c.has_leaf_mark=growth.has_growth_mark("leaf_mark")
    for r in buildings.get_completed_buildings(): c.completed_building_ids.append(r.building_id)
    return c.to_dict()
func get_notice_history()->Array[Dictionary]: return data.notice_history.duplicate(true) if data else []
func _matches(t:NoticeTemplate,c:NoticeConditionData)->bool:
    if not t.required_activity_location.is_empty() and c.recent_activity_location!=t.required_activity_location: return false
    if t.required_growth_mark_id=="leaf_mark" and not c.has_leaf_mark: return false
    if not t.required_farm_state.is_empty() and farm.get_farm_state()!=t.required_farm_state: return false
    if not t.required_building_id.is_empty() and not t.required_building_state.is_empty() and buildings.get_building_state(t.required_building_id)!=t.required_building_state: return false
    return true
func _has_alternative(c:NoticeConditionData,excluded:String)->bool:
    for t in _templates:
        if t.notice_id!=excluded and _matches(t,c): return true
    return false
func _has_notice_id(id:String)->bool:
    for raw in data.notice_history:
        if str(raw.get("notice_id",""))==id: return true
    return false
func _previous_notice_id()->String:
    var yesterday:=_date_key(-1)
    for raw in data.notice_history:
        if str(raw.get("date_key",""))==yesterday: return str(raw.get("notice_id",""))
    return ""
func _fallback_general(excluded:="")->NoticeTemplate:
    var list:Array[NoticeTemplate]=[]
    for t in _templates:
        if t.category=="general" and t.notice_id!=excluded: list.append(t)
    if list.is_empty():
        for t in _templates:
            if t.category=="general": return t
    return list.pick_random() if not list.is_empty() else null
func _load_templates()->void:
    _templates.clear(); if not FileAccess.file_exists(TEMPLATE_PATH): return
    var j:=JSON.new(); if j.parse(FileAccess.get_file_as_string(TEMPLATE_PATH))!=OK or not (j.data is Dictionary): return
    for raw:Variant in j.data.get("templates",[]):
        if raw is Dictionary:
            var t:=NoticeTemplate.from_dict(raw); if t.is_valid(): _templates.append(t)
func _repair_history()->void:
    var by_date:Dictionary={}
    for raw:Variant in data.notice_history:
        if not (raw is Dictionary): continue
        var date_key:=str(raw.get("date_key",""))
        if date_key.is_empty(): continue
        if not by_date.has(date_key):
            by_date[date_key]=raw.duplicate(true)
            continue
        var existing:Dictionary=by_date[date_key]
        if bool(raw.get("is_read",false)) and not bool(existing.get("is_read",false)):
            by_date[date_key]=raw.duplicate(true)
        elif float(raw.get("generated_at",0.0))>float(existing.get("generated_at",0.0)):
            by_date[date_key]=raw.duplicate(true)
    data.notice_history.clear()
    for date_key:Variant in by_date.keys(): data.notice_history.append(by_date[date_key])
    data.notice_history.sort_custom(func(a:Dictionary,b:Dictionary)->bool: return float(a.get("generated_at",0.0))<float(b.get("generated_at",0.0)))
func _repair_today()->void:
    if data.daily_notice.is_empty(): return
    if not DailyNoticeRecord.from_dict(data.daily_notice).is_valid_for_date(_date_key()): data.daily_notice={}

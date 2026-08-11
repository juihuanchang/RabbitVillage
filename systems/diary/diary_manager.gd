class_name DiaryManager
extends Node
signal journal_added(entry: JournalEntry)
signal journals_changed
var _journals: Array[JournalEntry]=[]
func create_journal_from_activity(active:ActiveActivityData)->JournalEntry:
    if active==null or active.activity_record_id.is_empty() or has_activity_record_id(active.activity_record_id): return null
    return _append(JournalGenerator.generate(active,_next_id()))
func create_growth_journal(rabbit_name:String,mark:String,at:float=-1.0)->JournalEntry:
    if mark.is_empty() or has_journal_for_growth_mark(mark): return null
    return _append(JournalGenerator.generate_growth_journal(rabbit_name,_next_id(),mark,at))
func generate_village_event_journal(id:String,rabbit_name:="Amy",at:float=-1.0,stage:=0)->JournalEntry:
    if id.is_empty() or has_journal_for_village_event(id): return null
    return _append(JournalGenerator.generate_village_event_journal(rabbit_name,_next_id(),id,at,stage))
func generate_construction_start_journal(r:ConstructionRecord,rabbit_name:="Amy",stage:=0)->JournalEntry:
    if r==null or r.construction_record_id.is_empty() or _has_construction_phase(r.construction_record_id,"construction"): return null
    return _append(JournalGenerator.generate_construction_journal(rabbit_name,_next_id(),r.construction_record_id,r.building_id,"start",r.started_at,stage))
func generate_construction_journal(r:ConstructionResult,rabbit_name:="Amy",stage:=0)->JournalEntry:
    if r==null or r.construction_record_id.is_empty() or _has_construction_phase(r.construction_record_id,"building_complete"): return null
    return _append(JournalGenerator.generate_construction_journal(rabbit_name,_next_id(),r.construction_record_id,r.building_id,"complete",r.completed_at,stage))
func generate_building_use_journal(r:BuildingUseResult,rabbit_name:="Amy",stage:=0)->JournalEntry:
    if r==null: return null
    var id:=r.building_use_record_id if not r.building_use_record_id.is_empty() else r.interaction_record_id
    if id.is_empty() or has_journal_for_building_use(id): return null
    return _append(JournalGenerator.generate_building_use_journal(rabbit_name,_next_id(),r,r.is_first_use or not _has_any_building_use(r.building_id),stage))
func generate_notice_journal(r:DailyNoticeRecord,rabbit_name:="Amy",stage:=0)->JournalEntry:
    if r==null or _has_notice_date(r.date_key): return null
    return _append(JournalGenerator.generate_notice_journal(rabbit_name,_next_id(),r,stage))
func generate_farm_growth_journal(c:FarmCycleData,rabbit_name:="Amy",stage:=0)->JournalEntry:
    if c==null or c.farm_cycle_id.is_empty() or has_journal_for_farm_cycle(c.farm_cycle_id): return null
    return _append(JournalGenerator.generate_farm_growth_journal(rabbit_name,_next_id(),c,not _has_type("farm_growth"),stage))
func generate_harvest_journal(r:HarvestResult,rabbit_name:="Amy",stage:=0)->JournalEntry:
    if r==null or r.harvest_record_id.is_empty() or has_journal_for_harvest(r.harvest_record_id): return null
    return _append(JournalGenerator.generate_harvest_journal(rabbit_name,_next_id(),r,r.is_first_harvest or not _has_type("harvest"),stage))
func generate_village_growth_journal(stage:int,rabbit_name:="Amy",at:float=-1.0)->JournalEntry:
    if stage<=0 or _has_stage(stage): return null
    return _append(JournalGenerator.generate_village_growth_journal(rabbit_name,_next_id(),stage,at))
func has_activity_record_id(id:String)->bool:
    for e in _journals:
        if not id.is_empty() and e.activity_record_id==id: return true
    return false
func has_journal_for_growth_mark(id:String)->bool:
    for e in _journals:
        if e.growth_mark_id==id: return true
    return false
func has_journal_for_village_event(id:String)->bool:
    for e in _journals:
        if e.village_event_id==id: return true
    return false
func has_journal_for_construction(id:String)->bool:
    for e in _journals:
        if e.construction_record_id==id: return true
    return false
func has_journal_for_building_use(id:String)->bool:
    for e in _journals:
        if e.building_use_record_id==id: return true
    return false
func has_journal_for_farm_cycle(id:String)->bool:
    for e in _journals:
        if e.journal_type=="farm_growth" and e.farm_cycle_id==id: return true
    return false
func has_journal_for_harvest(id:String)->bool:
    for e in _journals:
        if e.harvest_record_id==id: return true
    return false
func _has_construction_phase(id:String,typ:String)->bool:
    for e in _journals:
        if e.construction_record_id==id and e.journal_type==typ: return true
    return false
func _has_any_building_use(id:String)->bool:
    for e in _journals:
        if e.journal_type=="building_use" and e.building_id==id: return true
    return false
func _has_notice_date(d:String)->bool:
    for e in _journals:
        if e.journal_type=="notice" and e.notice_date==d: return true
    return false
func _has_type(t:String)->bool:
    for e in _journals:
        if e.journal_type==t: return true
    return false
func _has_stage(s:int)->bool:
    for e in _journals:
        if e.journal_type=="village_growth" and e.village_stage==s: return true
    return false
func get_all_journals()->Array[JournalEntry]:
    var out:Array[JournalEntry]=[]; out.assign(_journals); out.sort_custom(func(a,b): return a.created_at>b.created_at); return out
func get_latest_journal()->JournalEntry:
    var all:=get_all_journals(); return all[0] if not all.is_empty() else null
func get_journal_count()->int: return _journals.size()
func clear_journals()->void: _journals.clear(); journals_changed.emit()
func to_array()->Array[Dictionary]:
    var out:Array[Dictionary]=[]
    for e in _journals: out.append(e.to_dict())
    return out
func load_from_array(data:Array)->void:
    _journals.clear()
    for raw:Variant in data:
        if raw is Dictionary:
            var e:=JournalEntry.from_dict(raw)
            if e.is_valid() and not _duplicate(e): _journals.append(e)
    journals_changed.emit()
func _duplicate(e:JournalEntry)->bool:
    match e.journal_type:
        "growth": return has_journal_for_growth_mark(e.growth_mark_id)
        "activity","home": return has_activity_record_id(e.activity_record_id)
        "village_event": return has_journal_for_village_event(e.village_event_id)
        "construction","building_complete": return _has_construction_phase(e.construction_record_id,e.journal_type)
        "building_use": return has_journal_for_building_use(e.building_use_record_id)
        "notice": return _has_notice_date(e.notice_date)
        "farm_growth": return has_journal_for_farm_cycle(e.farm_cycle_id)
        "harvest": return has_journal_for_harvest(e.harvest_record_id)
        "village_growth": return _has_stage(e.village_stage)
    return false
func _append(e:JournalEntry)->JournalEntry:
    if e==null or not e.is_valid(): return null
    _journals.append(e); journal_added.emit(e); journals_changed.emit(); return e
func _next_id()->String: return "journal_%03d"%(_journals.size()+1)

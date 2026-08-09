class_name VillageEventManager
extends Node
signal village_event_created(event:VillageEventData)
signal village_event_completed(result:VillageEventResult)
var data:VillageData
var rabbit:RabbitData
var buildings:BuildingManager
var growth:GrowthManager
var events:Dictionary={}
var event_order:Array[String]=[]
func _init()->void:
    _register("village_rest_pavilion_001","村莊的新角落","小休息亭可以開始建造了。",0,0,"rest_pavilion")
    _register("village_notice_board_001","村莊需要一些消息","公告欄可以開始施工了。",1,2,"notice_board")
    _register("village_small_farm_001","村莊也需要食物","小農田可以開始施工了。",2,4,"carrot_farm","rest_pavilion",1)
    _register("village_growing_001","成長中的村莊","Amy 和村莊一起成長。",3,8,"","carrot_farm",0)
func _register(id:String,title:String,desc:String,level:int,activities:int,unlock:String,required_building:="",uses:=0)->void:
    var e:=VillageEventData.new(); e.event_id=id; e.title=title; e.description=desc; e.required_village_level=level; e.required_total_activity_count=activities; e.unlock_building_id=unlock; e.required_building_id=required_building; e.required_building_use_count=uses; events[id]=e; event_order.append(id)
func setup(v:VillageData,r:RabbitData,b:BuildingManager,g:GrowthManager)->void: data=v; rabbit=r; buildings=b; growth=g
func check_event_conditions()->VillageEventData:
    if data==null or rabbit==null or has_pending_event() or (growth!=null and growth.has_pending_growth_event()): return null
    for id in event_order:
        if can_trigger_event(id): return create_pending_event(id)
    return null
func can_trigger_event(id:String)->bool:
    if not events.has(id) or has_completed_event(id) or has_pending_event(): return false
    var e:VillageEventData=events[id]
    if data.progress.village_level<e.required_village_level or rabbit.total_activity_count<e.required_total_activity_count: return false
    if not e.required_building_id.is_empty():
        if not buildings.is_building_completed(e.required_building_id): return false
        if int(data.building_records.get(e.required_building_id,{}).get("use_count",0))<e.required_building_use_count: return false
    return true
func create_pending_event(id:String)->VillageEventData:
    if not can_trigger_event(id): return null
    var e:VillageEventData=events[id]; e.triggered_at=TimeManager.get_now(); e.state=VillageEventState.PENDING; data.pending_village_events=[e.to_dict()]; village_event_created.emit(e); return e
func has_pending_event()->bool: return data!=null and not data.pending_village_events.is_empty()
func get_pending_event()->VillageEventData: return VillageEventData.from_dict(data.pending_village_events[0]) if has_pending_event() else null
func confirm_event(id:String)->VillageEventResult:
    var e:=get_pending_event(); if e==null or e.event_id!=id or e.is_applied or has_completed_event(id): return null
    e.confirmed_at=TimeManager.get_now(); e.state=VillageEventState.COMPLETED; e.is_applied=true; if not e.unlock_building_id.is_empty(): buildings.unlock_building(e.unlock_building_id)
    if not data.completed_village_event_ids.has(id): data.completed_village_event_ids.append(id)
    data.progress.completed_village_event_count+=1; data.pending_village_events.clear(); var r:=VillageEventResult.new(); r.event_id=id; r.unlocked_building_id=e.unlock_building_id; r.applied_at=e.confirmed_at; village_event_completed.emit(r); return r
func has_completed_event(id:String)->bool: return data!=null and data.completed_village_event_ids.has(id)
func get_completed_events()->Array[VillageEventData]:
    var out:Array[VillageEventData]=[]
    for id in data.completed_village_event_ids:
        if events.has(id): out.append(events[id])
    return out
func CheckEventConditions()->VillageEventData: return check_event_conditions()
func CanTriggerEvent(id:String)->bool: return can_trigger_event(id)
func CreatePendingEvent(id:String)->VillageEventData: return create_pending_event(id)
func HasPendingEvent()->bool: return has_pending_event()
func GetPendingEvent()->VillageEventData: return get_pending_event()
func ConfirmEvent(id:String)->VillageEventResult: return confirm_event(id)
func ApplyEventResult(id:String)->VillageEventResult: return confirm_event(id)
func HasCompletedEvent(id:String)->bool: return has_completed_event(id)
func GetCompletedEvents()->Array[VillageEventData]: return get_completed_events()

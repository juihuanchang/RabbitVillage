class_name FarmManager
extends Node
signal farm_cycle_started(cycle:FarmCycleData)
signal farm_ready(cycle:FarmCycleData)
signal carrots_harvested(result:HarvestResult)
var data:VillageData
var farm:=FarmData.new()
var buildings:BuildingManager
var village:VillageManager
func setup(v:VillageData,b:BuildingManager,vm:VillageManager)->void:
    data=v; buildings=b; village=vm
    if not data.farm.is_empty(): farm=FarmData.from_dict(data.farm)
    if not buildings.is_building_completed("carrot_farm") and farm.current_cycle.is_empty(): farm.state=FarmState.LOCKED
    elif buildings.is_building_completed("carrot_farm") and farm.state==FarmState.LOCKED: farm.state=FarmState.IDLE
    _repair(); _sync()
func start_first_growth_cycle()->Dictionary:
    if not buildings.is_building_completed("carrot_farm"): return {"ok":false,"reason":"小農田尚未完工"}
    if has_active_growth_cycle() or is_farm_ready(): return {"ok":false,"reason":"目前已有生長週期"}
    if not data.conditions.claim_once("farm:first_cycle_created"): return {"ok":false,"reason":"第一輪已建立"}
    var c:=_create_cycle(); village.claim_reward_once("farm:first_growth",15); return {"ok":true,"reason":"","cycle":c}
func start_next_growth_cycle()->Dictionary:
    if not buildings.is_building_completed("carrot_farm"): return {"ok":false,"reason":"小農田尚未完工"}
    if has_active_growth_cycle() or is_farm_ready(): return {"ok":false,"reason":"目前已有生長週期"}
    return {"ok":true,"reason":"","cycle":_create_cycle()}
func _create_cycle()->FarmCycleData:
    var c:=FarmCycleData.new(); c.farm_cycle_id="farm_%d_%d"%[int(TimeManager.get_now()*1000000.0),randi_range(1000,9999)]; c.started_at=TimeManager.get_now(); c.ready_at=c.started_at+farm.growth_seconds; farm.current_cycle=c.to_dict(); farm.state=FarmState.GROWING; village.register_farm_cycle_started(); _sync(); farm_cycle_started.emit(c); return c
func get_farm_state()->String: return farm.state
func has_active_growth_cycle()->bool: return farm.state==FarmState.GROWING and not farm.current_cycle.is_empty()
func is_farm_ready()->bool: return farm.state==FarmState.READY and not farm.current_cycle.is_empty()
func get_farm_remaining_seconds()->float: return maxf(get_farm_ready_time()-TimeManager.get_now(),0.0) if has_active_growth_cycle() else 0.0
func get_farm_ready_time()->float: return float(farm.current_cycle.get("ready_at",0.0))
func get_current_farm_cycle()->FarmCycleData: return FarmCycleData.from_dict(farm.current_cycle) if not farm.current_cycle.is_empty() else null
func check_farm_ready_state()->bool:
    if not has_active_growth_cycle() or TimeManager.get_now()<get_farm_ready_time(): return false
    var c:=get_current_farm_cycle()
    if c==null or c.is_harvested or farm.completed_cycle_ids.has(c.farm_cycle_id): farm.current_cycle={}; farm.state=FarmState.IDLE; _sync(); return false
    farm.state=FarmState.READY; _sync(); farm_ready.emit(c); return true
func harvest_carrots()->HarvestResult:
    check_farm_ready_state(); if not is_farm_ready(): return null
    var c:=get_current_farm_cycle(); if c==null or c.is_harvested or farm.completed_cycle_ids.has(c.farm_cycle_id): return null
    var first:=data.progress.total_harvest_count==0; farm.completed_cycle_ids.append(c.farm_cycle_id); c.is_harvested=true; c.harvested_at=TimeManager.get_now(); farm.state=FarmState.IDLE; farm.current_cycle={}; var amount:=10; village.register_carrot_harvest(amount); village.add_village_experience(10)
    var r:=HarvestResult.new(); r.harvest_record_id="harvest_%d_%d"%[int(c.harvested_at*1000000.0),randi_range(1000,9999)]; r.farm_cycle_id=c.farm_cycle_id; r.amount=amount; r.harvested_at=c.harvested_at; r.village_experience_reward=10; r.is_first_harvest=first; _sync(); start_next_growth_cycle(); carrots_harvested.emit(r); return r
func get_carrot_amount()->int: return CarrotInventoryEntry.from_dict(data.carrot_inventory).amount
func get_total_harvest_count()->int: return data.progress.total_harvest_count
func migrate_legacy_state(legacy_state:String, remaining_seconds:float)->bool:
    if data==null or not buildings.is_building_completed("carrot_farm"): return false
    if has_active_growth_cycle() or is_farm_ready() or data.conditions.rewarded_keys.has("farm:first_cycle_created"): return false
    if legacy_state!="ready" and legacy_state!="sprout" and legacy_state!="growing": return false
    var now:=TimeManager.get_now()
    if legacy_state=="ready":
        farm.state=FarmState.READY; farm.current_cycle={"farm_cycle_id":"migrated_a_farm","started_at":now-60.0,"ready_at":now}
    elif legacy_state=="sprout" or legacy_state=="growing":
        farm.state=FarmState.GROWING
        var extra:=30.0 if legacy_state=="sprout" else 0.0
        farm.current_cycle={"farm_cycle_id":"migrated_a_farm","started_at":now,"ready_at":now+maxf(1.0,remaining_seconds+extra)}
    else:
        farm.state=FarmState.IDLE; farm.current_cycle={}
    _sync(); return true
func _sync()->void: data.farm=farm.to_dict()
func _repair()->void:
    if farm.current_cycle.is_empty(): return
    var c:=FarmCycleData.from_dict(farm.current_cycle)
    if c.farm_cycle_id.is_empty() or c.ready_at<c.started_at: farm.current_cycle={}; farm.state=FarmState.IDLE if buildings.is_building_completed("carrot_farm") else FarmState.LOCKED
    elif c.is_harvested or farm.completed_cycle_ids.has(c.farm_cycle_id): farm.current_cycle={}; farm.state=FarmState.IDLE

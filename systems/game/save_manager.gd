class_name SaveManager
extends Node
const SAVE_PATH:="user://save.json"
const SAVE_BACKUP_PATH:="user://save_backup.json"
const SAVE_TEMP_PATH:="user://save_temp.json"
var _rabbit_manager:RabbitManager
var _diary_manager:DiaryManager
var _activity_manager:ActivityManager
var _growth_manager:GrowthManager
var _growth_album_manager:GrowthAlbumManager
func setup(r:RabbitManager,d:DiaryManager,a:ActivityManager,g:GrowthManager=null,album:GrowthAlbumManager=null)->void: _rabbit_manager=r; _diary_manager=d; _activity_manager=a; _growth_manager=g; _growth_album_manager=album
func save_game()->bool:
    if not _has_dependencies(): return false
    var s:=SaveData.new(); s.save_version=SaveData.CURRENT_VERSION; s.last_saved_at=TimeManager.get_now()
    for rabbit in _rabbit_manager.get_all_rabbits():
        # IMPORTANT: saving must not write back to RabbitData.
        # village_data has a setter that emits data_changed; assigning it here
        # causes data_changed -> deferred save -> data_changed -> endless save loop.
        s.rabbits.append(rabbit.to_dict()); s.forest_experience=rabbit.forest_experience; s.fishing_experience=rabbit.fishing_experience; s.intimacy=rabbit.intimacy; s.forest_activity_count=rabbit.forest_activity_count; s.fishing_activity_count=rabbit.fishing_activity_count; s.home_activity_count=rabbit.home_activity_count; s.total_activity_count=rabbit.total_activity_count; s.unlocked_growth_marks=rabbit.unlocked_growth_marks.duplicate(true); s.pending_growth_event=rabbit.pending_growth_event.duplicate(true); _capture_week4(s,rabbit)
    if _activity_manager.active_activity!=null: s.current_activity=_activity_manager.active_activity.to_dict()
    s.completed_activity_ids=_activity_manager.get_completed_record_ids(); s.journals=_diary_manager.to_array(); s.village_journals=_diary_manager.get_village_journal_array()
    if _growth_manager!=null: s.all_activity_records=_growth_manager.get_all_activity_records(); s.growth_tendencies=_growth_manager.get_growth_tendencies()
    if _growth_album_manager!=null: s.growth_album_entries=_growth_album_manager.to_array()
    _backup(); return _write(s)
func load_or_create(default_rabbit:RabbitData)->RabbitData:
    var s:=_load(); if s==null: return _create_default(default_rabbit)
    s=migrate_save_data(s); _rabbit_manager.clear_rabbits(); _activity_manager.set_completed_record_ids(s.completed_activity_ids); _diary_manager.load_from_array(s.journals)
    for raw in s.rabbits:
        var r:=RabbitData.from_dict(raw); r.village_data=VillageData.from_dict(r.village_data).to_dict() if not r.village_data.is_empty() else s.village_data.duplicate(true); _rabbit_manager.add_rabbit(r)
    var rabbit:=_rabbit_manager.get_rabbit(default_rabbit.rabbit_name)
    if rabbit==null: rabbit=default_rabbit; _apply_week3(rabbit,s); rabbit.village_data=s.village_data.duplicate(true); _rabbit_manager.add_rabbit(rabbit)
    if _growth_manager!=null: _growth_manager.setup(rabbit); _growth_manager.load_from_save_data(s)
    if _growth_album_manager!=null: _growth_album_manager.load_from_array(s.growth_album_entries)
    _restore_activity(s,rabbit); return rabbit
func migrate_save_data(s:SaveData)->SaveData:
    if s==null: return null
    var v:=VillageData.from_dict(s.village_data) if not s.village_data.is_empty() else VillageData.create_migrated_week3_default()
    if s.village_data.is_empty() and (not s.buildings.is_empty() or not s.farm_data.is_empty() or not s.notice_history.is_empty()):
        var raw:={"progress":s.village_progress,"pending_village_events":s.pending_village_events,"completed_village_event_ids":s.completed_village_event_ids,"building_records":s.buildings,"construction_records":s.construction_records,"building_interaction_records":s.building_interaction_records,"daily_notice":s.daily_notice,"notice_history":s.notice_history,"farm":s.farm_data,"farm_cycle_records":s.farm_cycle_records,"harvest_records":s.harvest_records,"carrot_inventory":s.carrot_inventory,"building_history":s.building_history}; v=VillageData.from_dict(raw)
    s.village_data=v.to_dict(); _mirror(s,v); s.save_version=SaveData.CURRENT_VERSION; return s
func _capture_week4(s:SaveData,r:RabbitData)->void:
    var v:=VillageData.from_dict(r.village_data) if not r.village_data.is_empty() else VillageData.create_migrated_week3_default(); s.village_data=v.to_dict(); _mirror(s,v)
func _mirror(s:SaveData,v:VillageData)->void:
    s.village_progress=v.progress.to_dict(); s.pending_village_events=v.pending_village_events.duplicate(true); s.completed_village_event_ids=v.completed_village_event_ids.duplicate(); s.buildings=v.building_records.duplicate(true); s.construction_records=v.construction_records.duplicate(true); s.building_interaction_records=v.building_interaction_records.duplicate(true); s.daily_notice=v.daily_notice.duplicate(true); s.notice_history=v.notice_history.duplicate(true); s.farm_data=v.farm.duplicate(true); s.farm_cycle_records=v.farm_cycle_records.duplicate(true); s.harvest_records=v.harvest_records.duplicate(true); s.carrot_inventory=v.carrot_inventory.duplicate(true); s.building_history=v.building_history.duplicate(true)
func _restore_activity(s:SaveData,rabbit:RabbitData)->void:
    if not s.current_activity.is_empty():
        var owner:=_rabbit_manager.get_rabbit(str(s.current_activity.get("rabbit_name",rabbit.rabbit_name))); var restored:=ActiveActivityData.from_dict(s.current_activity,owner)
        if restored!=null and not restored.is_completed:
            var def:=_activity_manager.get_activity(restored.activity.activity_id); if def!=null: restored.activity=def
            _activity_manager.restore_activity(restored); return
    rabbit.is_away=false; rabbit.current_activity=""; rabbit.current_state=""
func _load()->SaveData:
    var p:=_read(SAVE_PATH); if p!=null: return p
    return _read(SAVE_BACKUP_PATH)
func _read(path:String)->SaveData:
    if not FileAccess.file_exists(path): return null
    var text:=FileAccess.get_file_as_string(path); if text.is_empty(): return null
    var j:=JSON.new(); if j.parse(text)!=OK or not (j.data is Dictionary): return null
    var s:=SaveData.from_dict(j.data); return s if s.is_supported_version() else null
func _create_default(r:RabbitData)->RabbitData:
    _rabbit_manager.clear_rabbits(); _diary_manager.clear_journals(); _activity_manager.restore_activity(null)
    if _growth_album_manager!=null: _growth_album_manager.clear_entries()
    if _growth_manager!=null: _growth_manager.setup(r); _growth_manager.load_from_save_data(SaveData.new())
    if r.village_data.is_empty(): r.village_data=VillageData.create_migrated_week3_default().to_dict()
    _rabbit_manager.add_rabbit(r); save_game(); return r
func _apply_week3(r:RabbitData,s:SaveData)->void:
    r.forest_experience=s.forest_experience; r.fishing_experience=s.fishing_experience; r.intimacy=s.intimacy; r.forest_activity_count=s.forest_activity_count; r.fishing_activity_count=s.fishing_activity_count; r.home_activity_count=s.home_activity_count; r.total_activity_count=s.total_activity_count
    if r.unlocked_growth_marks.is_empty(): r.unlocked_growth_marks=s.unlocked_growth_marks.duplicate(true)
    if r.pending_growth_event.is_empty(): r.pending_growth_event=s.pending_growth_event.duplicate(true)
func has_save_file()->bool: return FileAccess.file_exists(SAVE_PATH) or FileAccess.file_exists(SAVE_BACKUP_PATH)
func _has_dependencies()->bool: return _rabbit_manager!=null and _diary_manager!=null and _activity_manager!=null
func _backup()->void:
    if not FileAccess.file_exists(SAVE_PATH): return
    var src:=ProjectSettings.globalize_path(SAVE_PATH); var dst:=ProjectSettings.globalize_path(SAVE_BACKUP_PATH)
    if FileAccess.file_exists(SAVE_BACKUP_PATH): DirAccess.remove_absolute(dst)
    DirAccess.copy_absolute(src,dst)
func _write(s:SaveData)->bool:
    var f:=FileAccess.open(SAVE_TEMP_PATH,FileAccess.WRITE); if f==null: return false
    f.store_string(JSON.stringify(s.to_dict(),"\t")); f.close(); var temp:=ProjectSettings.globalize_path(SAVE_TEMP_PATH); var dst:=ProjectSettings.globalize_path(SAVE_PATH)
    if FileAccess.file_exists(SAVE_PATH): DirAccess.remove_absolute(dst)
    return DirAccess.rename_absolute(temp,dst)==OK
func SaveGame()->bool: return save_game()
func LoadGame(default_rabbit:RabbitData)->RabbitData: return load_or_create(default_rabbit)
func MigrateSaveData(data:SaveData)->SaveData: return migrate_save_data(data)

class_name JournalGenerator
extends RefCounted

static func generate(active: ActiveActivityData, journal_id: String) -> JournalEntry:
	if active == null or active.rabbit == null or active.activity == null:
		return null
	var title := "%s完成" % active.activity.activity_name
	var content := "%s 完成了%s，平安回到家。" % [
		active.rabbit.rabbit_name, active.activity.activity_name
	]
	var time := active.completed_at if active.completed_at > 0.0 else TimeManager.get_now()
	var date_data := Time.get_datetime_dict_from_unix_time(int(time))
	var date_text := "%04d/%02d/%02d" % [date_data.year, date_data.month, date_data.day]
	return JournalEntry.new(
		journal_id, active.activity_record_id, date_text, active.activity.activity_id,
		active.rabbit.rabbit_name, title, content, time
	)

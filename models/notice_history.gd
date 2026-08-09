class_name NoticeHistory
extends Resource

@export var records: Array[Dictionary] = []

func add_record(record: DailyNoticeRecord) -> bool:
    if record == null or record.notice_id.is_empty() or record.date_key.is_empty():
        return false
    for raw: Dictionary in records:
        if str(raw.get("date_key", "")) == record.date_key:
            return false
    records.append(record.to_dict())
    return true

func get_all() -> Array[Dictionary]:
    return records.duplicate(true)

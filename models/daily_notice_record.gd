class_name DailyNoticeRecord
extends NoticeData

@export var category := "general"

func to_dict() -> Dictionary:
    return {
        "notice_id": notice_id,
        "title": title,
        "content": content,
        "date_key": date_key,
        "notice_date": date_key,
        "generated_at": generated_at,
        "is_read": is_read,
        "first_read_at": first_read_at,
        "category": category
    }

static func from_dict(data: Dictionary) -> DailyNoticeRecord:
    var n := DailyNoticeRecord.new()
    n.notice_id = str(data.get("notice_id", ""))
    n.title = str(data.get("title", "村莊公告"))
    n.content = str(data.get("content", ""))
    n.date_key = str(data.get("date_key", data.get("notice_date", "")))
    n.generated_at = maxf(0.0, float(data.get("generated_at", 0.0)))
    n.is_read = bool(data.get("is_read", false))
    n.first_read_at = maxf(0.0, float(data.get("first_read_at", 0.0)))
    n.category = str(data.get("category", "general"))
    return n

func is_valid_for_date(expected_date: String) -> bool:
    return not notice_id.is_empty() and not content.is_empty() and date_key == expected_date

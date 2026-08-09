class_name DailyNoticeData
extends NoticeData

static func from_dict(data: Dictionary) -> DailyNoticeData:
	var notice := DailyNoticeData.new()
	notice.notice_id = str(data.get("notice_id", ""))
	notice.title = str(data.get("title", "村莊公告"))
	notice.content = str(data.get("content", ""))
	notice.date_key = str(data.get("date_key", ""))
	notice.generated_at = float(data.get("generated_at", 0.0))
	notice.is_read = bool(data.get("is_read", false))
	notice.first_read_at = float(data.get("first_read_at", 0.0))
	return notice

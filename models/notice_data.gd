class_name NoticeData
extends Resource
@export var notice_id := ""
@export var title := "村莊公告"
@export var content := ""
@export var date_key := ""
@export var generated_at := 0.0
@export var is_read := false
@export var first_read_at := 0.0
func to_dict() -> Dictionary: return {"notice_id": notice_id, "title": title, "content": content, "date_key": date_key, "generated_at": generated_at, "is_read": is_read, "first_read_at": first_read_at}
static func from_dict(d: Dictionary) -> NoticeData:
	var n := NoticeData.new(); n.notice_id = str(d.get("notice_id", "")); n.title = str(d.get("title", "村莊公告")); n.content = str(d.get("content", "")); n.date_key = str(d.get("date_key", "")); n.generated_at = float(d.get("generated_at", 0.0)); n.is_read = bool(d.get("is_read", false)); n.first_read_at = float(d.get("first_read_at", 0.0)); return n

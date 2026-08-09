class_name CarrotInventoryEntry
extends Resource

@export var food_id := "carrot"
@export var amount := 0
@export var first_obtained_at := 0.0
@export var last_obtained_at := 0.0
@export var total_obtained := 0

func add(amount_added: int, obtained_at: float = -1.0) -> void:
    var safe_amount := maxi(0, amount_added)
    if safe_amount <= 0:
        return
    var at_time := TimeManager.get_now() if obtained_at <= 0.0 else obtained_at
    if first_obtained_at <= 0.0:
        first_obtained_at = at_time
    last_obtained_at = at_time
    amount += safe_amount
    total_obtained += safe_amount

func to_dict() -> Dictionary:
    return {"food_id": "carrot", "amount": maxi(0, amount), "first_obtained_at": first_obtained_at, "last_obtained_at": last_obtained_at, "total_obtained": maxi(0, total_obtained)}

static func from_dict(data: Dictionary) -> CarrotInventoryEntry:
    var e := CarrotInventoryEntry.new()
    e.food_id = "carrot"
    e.amount = maxi(0, int(data.get("amount", 0)))
    e.first_obtained_at = maxf(0.0, float(data.get("first_obtained_at", 0.0)))
    e.last_obtained_at = maxf(0.0, float(data.get("last_obtained_at", 0.0)))
    e.total_obtained = maxi(e.amount, int(data.get("total_obtained", e.amount)))
    return e

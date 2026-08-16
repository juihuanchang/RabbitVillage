class_name CurrencyData
extends Resource

var currency_id := "coin"
var amount := 0
var total_earned := 0
var total_spent := 0

func to_dict() -> Dictionary:
	return {"currency_id": currency_id, "amount": amount,
		"total_earned": total_earned, "total_spent": total_spent}

static func from_dict(raw: Dictionary) -> CurrencyData:
	var data := CurrencyData.new(); data.currency_id = str(raw.get("currency_id", "coin"))
	data.amount = maxi(0, int(raw.get("amount", 0))); data.total_earned = maxi(data.amount, int(raw.get("total_earned", 0)))
	data.total_spent = maxi(0, int(raw.get("total_spent", 0))); return data

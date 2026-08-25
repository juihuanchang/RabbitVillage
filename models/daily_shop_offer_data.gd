class_name DailyShopOfferData
extends Resource

var product_id := ""
var day_key := ""
var final_price := 0
var daily_limit := 0

func to_dict() -> Dictionary:
	return {"product_id": product_id, "day_key": day_key, "final_price": final_price, "daily_limit": daily_limit}

static func from_dict(data: Dictionary) -> DailyShopOfferData:
	var offer := DailyShopOfferData.new(); offer.product_id = str(data.get("product_id", ""))
	offer.day_key = str(data.get("day_key", "")); offer.final_price = maxi(0, int(data.get("final_price", 0)))
	offer.daily_limit = maxi(0, int(data.get("daily_limit", 0))); return offer

class_name LifeLocationActivityData
extends Resource

var activity_id := ""
var display_name := ""
var energy_change := 0
var mood_change := 0
var intimacy_change := 0
var daily_limit := 3
var cooldown_seconds := 30.0

static func create(id: String, name: String, energy := 0, mood := 0, intimacy := 0) -> LifeLocationActivityData:
	var activity := LifeLocationActivityData.new(); activity.activity_id = id; activity.display_name = name
	activity.energy_change = energy; activity.mood_change = mood; activity.intimacy_change = intimacy; return activity

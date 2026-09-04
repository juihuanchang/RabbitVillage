extends SceneTree

var failures: Array[String] = []


func _init() -> void:
	_expect(ResourceLoader.exists("res://scenes  場景/home/village_expansion_ui.gd"), "Missing village_expansion_ui.gd")
	_expect(ResourceLoader.exists("res://scenes  場景/home/life_journey_ui.gd"), "Missing life_journey_ui.gd")
	_expect(ResourceLoader.exists("res://scenes  場景/cafe/CafeView.tscn"), "Missing CafeView.tscn")
	var home := load("res://scenes  場景/home/HomePage.tscn") as PackedScene
	_expect(home != null, "HomePage.tscn failed to load")
	if home != null:
		var state := home.get_state()
		var found_expansion_ui := false
		var found_life_journey_ui := false
		for index in state.get_node_count():
			if str(state.get_node_name(index)) == "VillageExpansionUI":
				found_expansion_ui = true
			if str(state.get_node_name(index)) == "LifeJourneyUI":
				found_life_journey_ui = true
		_expect(found_expansion_ui, "HomePage is missing VillageExpansionUI")
		_expect(found_life_journey_ui, "HomePage is missing LifeJourneyUI")
	var cafe := load("res://scenes  場景/cafe/CafeView.tscn") as PackedScene
	_expect(cafe != null, "CafeView scene failed to load")
	if failures.is_empty():
		print("VILLAGE_EXPANSION_SMOKE_OK")
		quit(0)
	else:
		for message: String in failures:
			push_error(message)
		quit(1)


func _expect(value: bool, message: String) -> void:
	if not value:
		failures.append(message)

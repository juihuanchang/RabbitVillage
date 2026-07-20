class_name RabbitData
extends Resource

@export var rabbit_name: String = ""
@export_range(0, 100) var hunger: int = 100:
	set(value):
		hunger = clampi(value, 0, 100)
@export_range(0, 100) var mood: int = 100:
	set(value):
		mood = clampi(value, 0, 100)
@export_range(0, 100) var energy: int = 100:
	set(value):
		energy = clampi(value, 0, 100)
@export var is_away: bool = false


func _init(
		initial_name: String = "",
		initial_hunger: int = 100,
		initial_mood: int = 100,
		initial_energy: int = 100
) -> void:
	rabbit_name = initial_name.strip_edges()
	hunger = initial_hunger
	mood = initial_mood
	energy = initial_energy

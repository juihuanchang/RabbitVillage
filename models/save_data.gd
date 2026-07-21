class_name SaveData
extends Resource


var version: int = 1
var rabbits: Array[Dictionary] = []
var journals: Array[Dictionary] = []


func to_dict() -> Dictionary:
	return {
		"version": version,
		"rabbits": rabbits,
		"journals": journals
	}


static func from_dict(data: Dictionary) -> SaveData:
	var save_data := SaveData.new()

	save_data.version = int(data.get("version", 1))

	var rabbit_data: Variant = data.get("rabbits", [])
	if rabbit_data is Array:
		for item: Variant in rabbit_data:
			if item is Dictionary:
				save_data.rabbits.append(item)

	var journal_data: Variant = data.get("journals", [])
	if journal_data is Array:
		for item: Variant in journal_data:
			if item is Dictionary:
				save_data.journals.append(item)

	return save_data
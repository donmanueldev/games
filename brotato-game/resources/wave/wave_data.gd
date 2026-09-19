extends Resource
class_name WaveData

enum SpawnType {
	FIXED,
	RANDOM
}

@export var from: int
@export var to: int
@export var wave_time := 20.0
@export var units: Array[WaveUnitData]

@export var spawn_type := SpawnType.RANDOM
@export var fixed_spawn_time := 1.0
@export var min_spawn_time := 1.0
@export var max_spawn_time := 2.5

func get_random_unit_scene() -> PackedScene:
	if units.is_empty():
		printerr("No units.")
		return null
	
	var total_weight := 0.0
	for unit_data: WaveUnitData in units:
		if unit_data and unit_data.weight > 0.0:
			total_weight += unit_data.weight
	
	if total_weight <= 0.0:
		printerr("Total weight <= 0")
		return null
	
	var random_weight := randf_range(0, total_weight)
	
	var current_weight_sum := 0.0
	for unit_data: WaveUnitData in units:
		if unit_data and unit_data.weight > 0.0:
			current_weight_sum += unit_data.weight
			if random_weight <= current_weight_sum:
				return unit_data.unit_scene
	
	return null


func is_valid_index(index: int) -> bool:
	return index >= from and index <= to

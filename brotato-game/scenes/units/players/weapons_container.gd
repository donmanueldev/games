extends Node2D
class_name WeaponsContainer

@onready var one: Node2D = $One
@onready var two: Node2D = $Two
@onready var three: Node2D = $Three
@onready var four: Node2D = $Four
@onready var five: Node2D = $Five
@onready var six: Node2D = $Six

func update_weapons_positions(weapons: Array[Weapon]) -> void:
	var count := weapons.size()
	var reference_node: Node2D
	match count:
		1: reference_node = one
		2: reference_node = two
		3: reference_node = three
		4: reference_node = four
		5: reference_node = five
		6: reference_node = six
	
	var markers := reference_node.get_children()
	if markers.size() != count:
		return
	
	for i in count:
		weapons[i].global_position = markers[i].global_position

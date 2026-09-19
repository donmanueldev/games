extends ItemBase
class_name ItemPassive

@export var add_value: float
@export var add_stats_id: String
@export var remove_value: float
@export var remove_stats_id: String

func get_description() -> String:
	var description := "[code]"
	
	if add_value != 0:
		description += "[color=green]+%s %s[/color]\n" % [add_value, add_stats_id]
	
	if remove_value != 0:
		description += "[color=red]-%s %s[/color]" % [remove_value, remove_stats_id]
	
	description += "[/code]"
	return description


func apply_passive_values() -> void:
	if add_value != 0:
		Global.player.stats[add_stats_id] += add_value
	
	if remove_value != 0:
		Global.player.stats[remove_stats_id] -= remove_value

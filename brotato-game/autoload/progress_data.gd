extends Node

const save_path := "user://data.sav"

var current_wave: int
var player_stats: Dictionary = {}
var current_player_name: String
var my_weapons: Array = []
var my_passives: Array = []

var has_saved_game: bool = false

func save_game() -> void:
	var save_dict: Dictionary = {
		"coins": Global.coins,
		"current_wave": 0,
		"player_stats": {
			"health": 1,
			"Damage": 20.0
		},
		"current_player_name": "",
		"equipped_weapons": [],
		"purchased_weapons": [],
		"purchased_passives": []
	}
	
	if Global.player and is_instance_valid(Global.player):
		save_dict["current_player_name"] = Global.player.stats.name
		var stats := Global.player.stats
		for stat in stats.get_script().get_script_property_list():
			if stat.type == TYPE_FLOAT or stat.type == TYPE_INT:
				save_dict["player_stats"][stat.name] = stats.get(stat.name)
		print(save_dict["player_stats"])
	
	var arena = get_tree().get_first_node_in_group("arena") as Arena
	save_dict["current_wave"] = arena.spawner.wave_index
	
	for weapon in Global.equipped_weapons:
		save_dict["equipped_weapons"].append(weapon.resource_path)
	
	var shop: ShopPanel = arena.shop_panel
	if shop:
		for card in shop.weapon_container.get_children():
			save_dict["purchased_weapons"].append(card.item.resource_path)
		for card in shop.passive_container.get_children():
			save_dict["purchased_passives"].append(card.item.resource_path)
	
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	var json_string := JSON.stringify(save_dict)
	file.store_string(json_string)
	file.close()


func load_game() -> void:
	if not FileAccess.file_exists(save_path):
		return
	
	var file := FileAccess.open(save_path, FileAccess.READ)
	var json_string := file.get_as_text()
	var data = JSON.parse_string(json_string)
	file.close()
	
	Global.coins = data.get("coins", 0)
	current_wave = data.get("current_wave", 1)
	current_player_name = data.get("current_player_name", "")
	
	my_weapons.clear()
	for path in data.get("purchased_weapons", []):
		my_weapons.append(load(path))
	
	my_passives.clear()
	for path in data.get("purchased_passives", []):
		my_passives.append(load(path))
	
	player_stats = data.get("player_stats", {})
	
	Global.equipped_weapons.clear()
	for path in data.get("equipped_weapons", []):
		Global.equipped_weapons.append(load(path))
	
	has_saved_game = true


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_game()
		print("Partida guardada")

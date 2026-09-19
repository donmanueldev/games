extends Panel
class_name UpgradePanel

const UPGRADE_CARD_SCENE = preload("uid://dylbhbilwtbnf")

@export var upgrades: Array[ItemUpgrade]

@onready var item_container: HBoxContainer = %ItemContainer


func load_upgrades(current_wave: int) -> void:
	if item_container.get_child_count() > 0:
		for child in item_container.get_children():
			child.queue_free()
	
	var config := Global.UPGRADE_PROBABILITY_CONFIG
	var selected_upgrades := Global.select_items_for_offer(upgrades, current_wave, config)
	for upgrade: ItemUpgrade in selected_upgrades:
		var upgrade_instance := UPGRADE_CARD_SCENE.instantiate()
		item_container.add_child(upgrade_instance)
		upgrade_instance.item = upgrade

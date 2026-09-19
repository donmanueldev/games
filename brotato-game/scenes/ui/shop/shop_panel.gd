extends Panel
class_name ShopPanel

signal on_shop_next_wave

const SHOP_CARD_SCENE = preload("uid://cps0mcnvb48mt")

@export var shop_items: Array[ItemBase]

@onready var items_container: HBoxContainer = %ItemsContainer
@onready var passive_container: GridContainer = %PassiveContainer
@onready var weapon_container: GridContainer = %WeaponContainer
@onready var combine_button: Button = %CombineButton

var context_card: ItemCard

func _ready() -> void:
	for child in passive_container.get_children(): child.queue_free()
	for child in weapon_container.get_children(): child.queue_free()


func load_shop(current_wave: int) -> void:
	for child in items_container.get_children(): child.queue_free()
	
	var config := Global.SHOP_PROBABILITY_CONFIG
	var selected_items := Global.select_items_for_offer(shop_items, current_wave, config)
	for shop_item: ItemBase in selected_items:
		var instance := SHOP_CARD_SCENE.instantiate() as ShopCard
		items_container.add_child(instance)
		instance.shop_item = shop_item
		instance.on_item_purchased.connect(_on_item_purchased)


func create_item_card() -> ItemCard:
	var item_card := Global.ITEM_CARD_SCENE.instantiate()
	item_card.on_item_card_selected.connect(_on_item_card_selected)
	return item_card


func create_item_weapon(weapon: ItemWeapon) -> void:
	var item_card := create_item_card()
	weapon_container.add_child(item_card)
	item_card.item = weapon


func _on_new_wave_button_pressed() -> void:
	SoundManager.play_sound(SoundManager.Sound.UI_CLICK)
	on_shop_next_wave.emit()


func _on_item_purchased(item: ItemBase) -> void:
	SoundManager.play_sound(SoundManager.Sound.UI_CLICK)
	
	var item_card := create_item_card()
	
	if item.item_type == ItemBase.ItemType.WEAPON:
		weapon_container.add_child(item_card)
		var weapon := item as ItemWeapon
		Global.player.add_weapon(weapon)
		Global.equipped_weapons.append(weapon)
	
	elif item.item_type == ItemBase.ItemType.PASSIVE:
		passive_container.add_child(item_card)
		var passive := item as ItemPassive
		passive.apply_passive_values()
	
	item_card.item = item


func _on_item_card_selected(card: ItemCard) -> void:
	context_card = card
	
	var can_merge := false
	if context_card and context_card.item.item_type == ItemBase.ItemType.WEAPON:
		var count := 0
		for weapon: ItemWeapon in Global.equipped_weapons:
			if weapon.item_name == context_card.item.item_name:
				count += 1
		
		if count >= 2:
			can_merge = true
	
	combine_button.disabled = not can_merge


func _on_combine_button_pressed() -> void:
	SoundManager.play_sound(SoundManager.Sound.UI_CLICK)
	
	if not context_card:
		return
	
	var clicked_weapon := context_card.item as ItemWeapon
	if not clicked_weapon.upgrade_to:
		return
	
	var weapons_to_remove := Global.player.current_weapons.filter(func(w: Weapon):
		return w.data.item_name == clicked_weapon.item_name).slice(0, 2)
	
	var cards_to_remove := weapon_container.get_children().filter(func(c: ItemCard):
		return c.item.item_name == clicked_weapon.item_name).slice(0, 2)
	
	if weapons_to_remove.size() < 2 or cards_to_remove.size() < 2:
		return
	
	for weapon: Weapon in weapons_to_remove:
		Global.player.current_weapons.erase(weapon)
		Global.equipped_weapons.erase(weapon.data)
		weapon.queue_free()
	
	for card: ItemCard in cards_to_remove:
		card.queue_free()
	
	var upgraded_weapon := load(clicked_weapon.upgrade_to.resource_path)
	Global.player.add_weapon(upgraded_weapon)
	Global.equipped_weapons.append(upgraded_weapon)
	
	var new_card := create_item_card()
	weapon_container.add_child(new_card)
	new_card.item = upgraded_weapon
	
	context_card = null


func _on_sell_weapon_button_pressed() -> void:
	SoundManager.play_sound(SoundManager.Sound.UI_CLICK)
	
	if not context_card:
		return
	
	var clicked_weapon := context_card.item as ItemWeapon
	var coins := clicked_weapon.item_cost * 0.75
	
	var weapon_to_remove: Weapon = Global.player.current_weapons.filter(func(w: Weapon):
		return w.data.item_name == clicked_weapon.item_name).front()
	
	if weapon_to_remove:
		Global.player.current_weapons.erase(weapon_to_remove)
		Global.equipped_weapons.erase(weapon_to_remove.data)
		weapon_to_remove.queue_free()
	
	context_card.queue_free()
	context_card = null
	
	Global.coins += coins

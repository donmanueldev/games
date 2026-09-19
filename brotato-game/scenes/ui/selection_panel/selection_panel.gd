extends Panel
class_name SelectionPanel

signal on_selection_completed

const SELECTION_CARD = preload("uid://bth1bkpqd575a")

@export var player_list: Array[UnitStats]
@export var weapon_list: Array[ItemWeapon]

@onready var players_container: HBoxContainer = %PlayersContainer
@onready var weapons_container: HBoxContainer = %WeaponsContainer

@onready var player_icon: TextureRect = %PlayerIcon
@onready var player_name: Label = %PlayerName
@onready var player_title: Label = %PlayerTitle
@onready var player_description: RichTextLabel = %PlayerDescription

func _ready() -> void:
	for child in players_container.get_children(): child.queue_free()
	for child in weapons_container.get_children(): child.queue_free()
	
	load_players()
	load_weapons()
	show_player_info(false)


func load_players() -> void:
	if player_list.is_empty():
		return
	
	for player: UnitStats in player_list:
		var card := SELECTION_CARD.instantiate() as SelectionCard
		card.pressed.connect(_on_player_selected.bind(player))
		players_container.add_child(card)
		card.set_icon(player.icon)


func load_weapons() -> void:
	if weapon_list.is_empty():
		return
	
	for weapon: ItemWeapon in weapon_list:
		var card := SELECTION_CARD.instantiate() as SelectionCard
		card.pressed.connect(_on_weapon_selected.bind(weapon))
		weapons_container.add_child(card)
		card.set_icon(weapon.item_icon)


func show_player_info(value: bool) -> void:
	player_icon.visible = value
	player_name.visible = value
	player_title.visible = value
	player_description.visible = value


func _on_player_selected(player: UnitStats) -> void:
	Global.main_player_selected = player
	show_player_info(true)
	
	player_icon.texture = player.icon
	player_name.text = player.name
	player_description.text = "[code]Health: [color=green]%s[/color]\nDamage: [color=green]%s[/color]\nSpeed: [color=green]%s[/color]\nLuck: [color=green]%s[/color]\nBlock Chance: [color=green]%s[/color][/code]" % [player.health, player.damage, player.speed, player.luck, player.block_chance]        


func _on_weapon_selected(weapon: ItemWeapon) -> void:
	Global.main_weapon_selected = weapon


func _on_custom_button_pressed() -> void:
	SoundManager.play_sound(SoundManager.Sound.UI_CLICK)
	
	if not Global.main_player_selected and not Global.main_weapon_selected:
		return
	
	on_selection_completed.emit()
	hide()

extends Node2D
class_name Arena

@export var normal_color: Color
@export var blocked_color: Color
@export var critical_color: Color
@export var hp_reg_color: Color
@export var use_save_state: bool

@onready var wave_index_label: Label = %WaveIndexLabel
@onready var wave_timer_label: Label = %WaveTimerLabel
@onready var spawner: Spawner = $Spawner
@onready var upgrade_panel: UpgradePanel = %UpgradePanel
@onready var shop_panel: ShopPanel = %ShopPanel
@onready var selection_panel: SelectionPanel = %SelectionPanel
@onready var coins_bag: CoinsBag = %CoinsBag

var gold_list: Array[Coins]

func _ready() -> void:
	Global.on_create_block_text.connect(_on_create_block_text)
	Global.on_create_damage_text.connect(_on_create_damage_text)
	Global.on_create_heal_text.connect(_on_create_heal_text)
	Global.on_upgrade_selected.connect(_on_upgrade_selected)
	Global.on_enemy_died.connect(_on_enemy_died)
	
	if use_save_state:
		ProgressData.load_game()
		if ProgressData.has_saved_game:
			selection_panel.hide()
			shop_panel.show()
			
			var player_scene = Global.available_players[ProgressData.current_player_name]
			Global.player = player_scene.instantiate()
			add_child(Global.player)
			
			for stat_name in ProgressData.player_stats:
				Global.player.stats.set(stat_name, ProgressData.player_stats[stat_name])
			
			for weapon_data in Global.equipped_weapons:
				Global.player.add_weapon(weapon_data)
			
			for weapon_data in ProgressData.my_weapons:
				shop_panel.create_item_weapon(weapon_data)
			
			for passive_data in ProgressData.my_passives:
				var item_card = shop_panel.create_item_card()
				shop_panel.passive_container.add_child(item_card)
				item_card.item = passive_data
			
			spawner.wave_index = ProgressData.current_wave
			shop_panel.load_shop(spawner.wave_index)
			Global.game_paused = true


func _process(delta: float) -> void:
	if Global.game_paused: return
	wave_index_label.text = spawner.get_wave_text()
	wave_timer_label.text = spawner.get_wave_timer_text()


func create_floating_text(unit: Node2D) -> FloatingText:
	var instance := Global.FLOATING_TEXT_SCENE.instantiate() as FloatingText
	get_tree().root.add_child(instance)
	var random_pos := randf_range(0, TAU) * 35
	var spawn_pos := unit.global_position + Vector2.RIGHT.rotated(random_pos)
	instance.global_position = spawn_pos
	return instance


func start_new_wave() -> void:
	Global.game_paused = false
	Global.player.update_player_for_new_wave()
	spawner.wave_index += 1
	spawner.start_wave()


func show_upgrades() -> void:
	upgrade_panel.load_upgrades(spawner.wave_index)
	upgrade_panel.show()


func spawn_coins(enemy: Enemy) -> void:
	var random_angle := randf_range(0, TAU)
	var offset := Vector2.RIGHT.rotated(random_angle) * 35
	var spawn_pos := enemy.global_position + offset
	
	var instance := Global.COINS_SCENE.instantiate()
	gold_list.append(instance)
	
	instance.global_position = spawn_pos
	instance.value = enemy.stats.coin_drop
	call_deferred("add_child", instance)


func clear_arena() -> void:
	if gold_list.size() > 0:
		var target_center_pos := coins_bag.global_position + coins_bag.size / 2
		for coin: Coins in gold_list:
			if is_instance_valid(coin):
				coin.set_collection_target(target_center_pos)
	
	gold_list.clear()
	spawner.clear_enemies()


func _on_create_block_text(unit: Node2D) -> void:
	var text := create_floating_text(unit)
	text.setup_text("Blocked", blocked_color)


func _on_create_damage_text(unit: Node2D, hitbox: HitboxComponent) -> void:
	var text := create_floating_text(unit)
	var color := critical_color if hitbox.critical else normal_color
	text.setup_text(str(hitbox.damage), color)


func _on_create_heal_text(unit: Node2D, value: float) -> void:
	var text := create_floating_text(unit)
	text.setup_text("+ %d" % value, hp_reg_color)


func _on_spawner_on_wave_completed() -> void:
	if not Global.player:
		return
	
	clear_arena()
	await get_tree().create_timer(1).timeout
	Global.get_harvesting_coins()
	show_upgrades()
	clear_arena()


func _on_upgrade_selected() -> void:
	upgrade_panel.hide()
	shop_panel.load_shop(spawner.wave_index)
	shop_panel.show()


func _on_shop_panel_on_shop_next_wave() -> void:
	shop_panel.hide()
	start_new_wave()


func _on_enemy_died(enemy: Enemy) -> void:
	spawn_coins(enemy)


func _on_selection_panel_on_selection_completed() -> void:
	var player := Global.get_selected_player()
	add_child(player)
	
	player.add_weapon(Global.main_weapon_selected)
	shop_panel.create_item_weapon(Global.main_weapon_selected)
	Global.equipped_weapons.append(Global.main_weapon_selected)
	
	spawner.start_wave()
	Global.game_paused = false

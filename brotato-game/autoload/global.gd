extends Node

signal on_create_block_text(unit: Node2D)
signal on_create_damage_text(unit: Node2D, info: HitboxComponent)
signal on_create_heal_text(unit: Node2D, value: float)

signal on_upgrade_selected
signal on_enemy_died(enemy: Enemy)

const FLASH_MATERIAL = preload("uid://br5yx1h5io73o")
const FLOATING_TEXT_SCENE = preload("uid://b6u6hp6ck5aux")

const COMMON_STYLE = preload("uid://dvm50xvp1nb7j")
const EPIC_STYLE = preload("uid://cl1p8hbl57322")
const LEGENDARY_STYLE = preload("uid://bs5fkpq52qfl3")
const RARE_STYLE = preload("uid://b0axckjnxn2h2")

const COINS_SCENE = preload("uid://d2ska12707rk3")
const ITEM_CARD_SCENE = preload("uid://cqd7gxxeb4hju")
const SPAWN_EFFECT_SCENE = preload("uid://beksjf58ejua4")

const UPGRADE_PROBABILITY_CONFIG = {
	"rare" : { "start_wave": 2, "base_mult": 0.06 },
	"epic" : { "start_wave": 4, "base_mult": 0.02 },
	"legendary" : { "start_wave": 7, "base_mult": 0.0023 },
}

const SHOP_PROBABILITY_CONFIG = {
	"rare" : { "start_wave": 2, "base_mult": 0.10 },
	"epic" : { "start_wave": 4, "base_mult": 0.05 },
	"legendary" : { "start_wave": 7, "base_mult": 0.01 },
}

const TIER_COLORS: Dictionary[UpgradeTier, Color] = {
	UpgradeTier.RARE: Color(0.0, 0.557, 0.741),
	UpgradeTier.EPIC: Color(0.478, 0.251, 0.71),
	UpgradeTier.LEGENDARY: Color(0.906, 0.212, 0.212)
}

enum UpgradeTier {
	COMMON,
	RARE,
	EPIC,
	LEGENDARY
}

var available_players: Dictionary[String, PackedScene] = {
	"Brawler": preload("uid://d3yi6tnvpsxfo"),
	"Bunny": preload("uid://bm1gv88kpq8df"),
	"Crazy": preload("uid://xgep30mgy4iv"),
	"Knight": preload("uid://cxo7j15umxys6"),
	"Well Rounded": preload("uid://ylarq2r0auqf"),
}

var coins: int = 500
var player: Player
var game_paused: bool

var main_player_selected: UnitStats
var main_weapon_selected: ItemWeapon

var selected_weapon: ItemWeapon
var equipped_weapons: Array[ItemWeapon]

func get_harvesting_coins() -> void:
	coins += player.stats.harvesting


func get_selected_player() -> Player:
	var player_path: PackedScene = available_players[main_player_selected.name]
	var player_instance := player_path.instantiate()
	player = player_instance
	return player


func get_chance_sucess(chance: float) -> bool:
	var random := randf_range(0, 1)
	if random < chance:
		return true
	return false


func get_tier_style(tier: UpgradeTier) -> StyleBoxFlat:
	match tier:
		UpgradeTier.COMMON:
			return COMMON_STYLE
		UpgradeTier.RARE:
			return RARE_STYLE
		UpgradeTier.EPIC:
			return EPIC_STYLE
		_:
			return LEGENDARY_STYLE


func calculate_tier_probability(current_wave: int, config: Dictionary) -> Array[float]:
	var common_chance := 0.0
	var rare_chance := 0.0
	var epic_chance := 0.0
	var legendary_chance := 0.0
	
	# RARE
	if current_wave >= config.rare.start_wave:
		rare_chance = min(1.0, (current_wave - 1) * config.rare.base_mult)
	
	# EPIC
	if current_wave >= config.epic.start_wave:
		epic_chance = min(1.0, (current_wave - 3) * config.epic.base_mult)
	
	# LEGENDARY
	if current_wave >= config.legendary.start_wave:
		legendary_chance = min(1.0, (current_wave - 6) * config.legendary.base_mult)
	
	# LUCK
	# Player -> Luck 10 -> 10% chance -> 1.1 Mult
	var luck_factor := 1.0 + (Global.player.stats.luck / 100.0)
	rare_chance *= luck_factor
	epic_chance *= luck_factor
	legendary_chance *= luck_factor
	
	# Normalize probabilities
	var total_non_common_chance := rare_chance + epic_chance + legendary_chance
	if total_non_common_chance > 1.0:
		var scale_down := 1.0 / total_non_common_chance
		rare_chance *= scale_down
		epic_chance *= scale_down
		legendary_chance *= scale_down
		total_non_common_chance = 1.0
	
	common_chance = 1.0 - total_non_common_chance
	
	print("Wave: %d, Luck: %.1f => Chances C:%.2f R:%.2f E:%.2f L:%.2f" %
	[current_wave, Global.player.stats.luck, common_chance, rare_chance, epic_chance, legendary_chance])
	
	return [
		max(0.0, common_chance),
		max(0.0, rare_chance),
		max(0.0, epic_chance),
		max(0.0, legendary_chance)
	]


func select_items_for_offer(item_pool: Array, current_wave: int, config: Dictionary) -> Array:
	var tier_chances: Array[float] = calculate_tier_probability(current_wave, config)
	
	var legendary_limit := tier_chances[3]
	var epic_limit := legendary_limit + tier_chances[2]
	var rare_limit := epic_limit + tier_chances[1]
	
	var offered_items: Array = []
	
	while offered_items.size() < 4:
		var roll := randf()
		var chosen_tier_index := 0
		if roll < legendary_limit:
			chosen_tier_index = 3 # Legendary
		elif roll < epic_limit:
			chosen_tier_index = 2 # Epic
		elif roll < rare_limit:
			chosen_tier_index = 1 # Rare
		
		var potential_items: Array = []
		var current_search_tier_index := chosen_tier_index
		
		while potential_items.is_empty() and current_search_tier_index >= 0:
			potential_items = item_pool.filter(func(item: ItemBase): return item.item_tier == current_search_tier_index)
			
			if potential_items.is_empty():
				current_search_tier_index -= 1
			else:
				break
		
		if not potential_items.is_empty():
			var random_item = potential_items.pick_random()
			
			if not offered_items.has(random_item):
				offered_items.append(random_item)
	
	return offered_items

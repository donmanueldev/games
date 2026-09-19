extends Resource
class_name UnitStats

enum UnitType {
	Player,
	Enemy
}

@export var name: String
@export var type: UnitType
@export var icon: Texture2D
@export var health := 1.0
@export var health_increase_per_wave := 1.0
@export var damage := 1.0
@export var damage_increase_per_wave := 1.0
@export var speed := 300.0
@export var luck := 1.0
@export var block_chance := 0.0
@export var coin_drop := 1
@export var hp_regen := 0.0
@export var life_steal := 0.0
@export var harvesting := 0.0

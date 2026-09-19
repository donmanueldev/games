extends Node2D
class_name ChargeAttackBehavior

@export var enemy: Enemy
@export var anim_player: AnimationPlayer
@export var cooldown := 3.0

var is_charging := false 
var current_cooldown := 0.0
var charge_atk_position: Vector2

func _ready() -> void:
	current_cooldown = cooldown

func _process(delta: float) -> void:
	if is_charging:
		enemy.global_position = enemy.global_position.move_toward(charge_atk_position, (enemy.stats.speed * 5) * delta)
		if enemy.global_position.distance_squared_to(charge_atk_position) < pow(50, 2):
			end_charge()
	else:
		if current_cooldown > 0:
			current_cooldown -= delta
		else:
			if is_instance_valid(Global.player):
				charge_atk_position = Global.player.global_position
				start_charge()


func start_charge() -> void:
	enemy.can_move = false
	anim_player.play("charge")
	await anim_player.animation_finished
	is_charging = true


func end_charge() -> void:
	is_charging = false
	current_cooldown = cooldown
	enemy.can_move = true

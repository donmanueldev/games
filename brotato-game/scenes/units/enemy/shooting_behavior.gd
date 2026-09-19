extends Node2D
class_name ShootingBehavior

@export var enemy: Enemy
@export var fire_pos: Marker2D
@export var cooldown := 4.0
@export var projectile_count := 3
@export var arc_angle := 45.0
@export var projectile_scene: PackedScene
@export var projectile_speed := 1500.0

var current_cooldown := 0.0

func _ready() -> void:
	current_cooldown = cooldown


func _process(delta: float) -> void:
	if Global.game_paused: return
	
	if current_cooldown > 0:
		current_cooldown -= delta
	else:
		shoot()
		current_cooldown = cooldown


func shoot() -> void:
	if not is_instance_valid(Global.player):
		return
	
	enemy.can_move = false
	
	var direction := enemy.global_position.direction_to(Global.player.global_position)
	var start_angle := -arc_angle / 2.0
	var step_angle := arc_angle / float(projectile_count - 1) if projectile_count > 1 else 0.0
	
	for i in projectile_count:
		var projectile := projectile_scene.instantiate() as Projectile
		get_tree().current_scene.add_child(projectile)
		projectile.global_position = fire_pos.global_position
		
		var rotation_direction := direction.rotated(deg_to_rad(start_angle + step_angle * i))
		var velocity = rotation_direction * projectile_speed
		projectile.setup_projectile(velocity, enemy.stats.damage, false, 0, enemy)
	
	await get_tree().create_timer(1).timeout
	enemy.can_move = true

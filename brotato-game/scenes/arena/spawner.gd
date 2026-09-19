extends Node2D
class_name Spawner

signal on_wave_completed

@export var spawn_area_size := Vector2(1000, 500)
@export var waves_data: Array[WaveData]
@export var enemy_collection: Array[UnitStats]

@onready var wave_timer: Timer = $WaveTimer
@onready var spawn_timer: Timer = $SpawnTimer

var wave_index := 1
var current_wave_data: WaveData
var spawned_enemies: Array[Enemy] = []


func find_wave_data() -> WaveData:
	for wave: WaveData in waves_data:
		if wave and wave.is_valid_index(wave_index):
			return wave
	return null

func start_wave() -> void:
	current_wave_data = find_wave_data()
	if not current_wave_data:
		printerr("No valid wave.")
		spawn_timer.stop()
		wave_timer.stop()
		return
	
	wave_timer.wait_time = current_wave_data.wave_time
	wave_timer.start()
	
	start_spawn_timer()

func start_spawn_timer() -> void:
	match current_wave_data.spawn_type:
		WaveData.SpawnType.FIXED:
			spawn_timer.wait_time = current_wave_data.fixed_spawn_time
		WaveData.SpawnType.RANDOM:
			var min_t := current_wave_data.min_spawn_time
			var max_t := current_wave_data.max_spawn_time
			spawn_timer.wait_time = randf_range(min_t, max_t)
	
	if spawn_timer.is_stopped():
		spawn_timer.start()


func get_random_spawn_position() -> Vector2:
	var random_x := randf_range(-spawn_area_size.x, spawn_area_size.x)
	var random_y := randf_range(-spawn_area_size.y, spawn_area_size.y)
	return Vector2(random_x, random_y)


func spawn_enemy() -> void:
	var enemy_scene := current_wave_data.get_random_unit_scene() as PackedScene
	if enemy_scene:
		var spawn_pos := get_random_spawn_position()
		
		var spawn_effect := Global.SPAWN_EFFECT_SCENE.instantiate()
		get_parent().add_child(spawn_effect)
		spawn_effect.global_position = spawn_pos
		await spawn_effect.anim_player.animation_finished
		spawn_effect.queue_free()
		
		var instance := enemy_scene.instantiate() as Enemy
		instance.global_position = spawn_pos
		get_parent().add_child(instance)
		spawned_enemies.append(instance)
	
	start_spawn_timer()


func clear_enemies() -> void:
	if spawned_enemies.size() > 0:
		for enemy: Enemy in spawned_enemies:
			if is_instance_valid(enemy):
				enemy.destroy_enemy()
	
	spawned_enemies.clear()


func update_enemies_new_wave() -> void:
	for stats: UnitStats in enemy_collection:
		stats.health += stats.health_increase_per_wave
		stats.damage += stats.damage_increase_per_wave


func get_wave_timer_text() -> String:
	return str(int(wave_timer.time_left))


func get_wave_text() -> String:
	return "Wave %d" % wave_index


func _on_spawn_timer_timeout() -> void:
	if not current_wave_data or wave_timer.is_stopped():
		spawn_timer.stop()
		return
	
	spawn_enemy()


func _on_wave_timer_timeout() -> void:
	Global.game_paused = true
	on_wave_completed.emit()
	spawn_timer.stop()
	clear_enemies()
	update_enemies_new_wave()

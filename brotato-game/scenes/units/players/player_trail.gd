extends Line2D
class_name PlayerTrail

@export var player: Player
@export var trail_length := 25
@export var trail_duration := 1

@onready var trail_timer: Timer = %TrailTimer

var points_array: Array[Vector2] = []
var is_active := false

func _process(_delta: float) -> void:
	if not is_active:
		return
	
	points_array.append(player.global_position)
	if points_array.size() > trail_length:
		points_array.pop_front()
	
	points = points_array


func start_trail() -> void:
	is_active = true
	call_deferred("reparent", player)
	clear_points()
	points_array.clear()
	trail_timer.start(trail_duration)

func _on_trail_timer_timeout() -> void:
	is_active = false
	clear_points()
	points_array.clear()

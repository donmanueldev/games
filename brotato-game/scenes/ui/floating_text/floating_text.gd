extends Node2D
class_name FloatingText

@onready var label: Label = $Label

func setup_text(value: String, color: Color) -> void:
	label.text = value
	modulate = color
	scale = Vector2.ZERO
	
	rotation = deg_to_rad(randf_range(-10, 10))
	var random_scale := randf_range(0.8, 1.6)
	
	var tween := create_tween()
	
	tween.parallel().tween_property(self, "scale", Vector2.ONE * random_scale, 0.4)
	tween.parallel().tween_property(self, "global_position", global_position + Vector2.UP * 15, 0.4)
	
	tween.tween_interval(0.5)
	
	tween.parallel().tween_property(self, "scale", Vector2.ZERO, 0.4)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.4)
	
	await tween.finished
	queue_free()

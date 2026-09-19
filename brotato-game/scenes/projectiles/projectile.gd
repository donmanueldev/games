extends Node2D
class_name Projectile

@export var hitbox: HitboxComponent

var velocity: Vector2

func _ready() -> void:
	hitbox.enable()

func _process(delta: float) -> void:
	position += velocity * delta

func setup_projectile(velocity: Vector2, 
damage: float, critical: bool, 
knockback: float, unit: Node2D) -> void:
	self.velocity = velocity
	rotation = velocity.angle()
	hitbox.setup(damage, critical, knockback, unit)


func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()


func _on_hitbox_component_on_hit_hurtbox(hurtbox: HurtboxComponent) -> void:
	queue_free()

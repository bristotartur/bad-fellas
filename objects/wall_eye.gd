extends Area2D

@export var is_target := false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var receiver_shape: CollisionShape2D = $Receiver/CollisionShape2D

func _ready() -> void:
	receiver_shape.disabled = not is_target
	sprite.play("open")

func set_eye_animation(animation_name: StringName) -> void:
	sprite.play(animation_name)

func get_laser_point() -> Vector2:
	return $LaserPoint.global_position

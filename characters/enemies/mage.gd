extends CharacterBody2D

const STEP_DISTANCE := 4.0
const STEPS_FROM_CENTER := 12
const FIREBALL := preload("res://objects/fireball.tscn")
const HIT_FLASH := preload("res://characters/hit_flash.gd")

@export var fire_interval := 4.0

var step_offset := 0
var direction := 1
var frame_progress := 0.0
var fire_timer := 0.0
var hits := 0
var is_dying := false

@onready var animations: AnimatedSprite2D = $Animations

func _physics_process(delta: float) -> void:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player != null and player.get_parent() == get_parent():
		fire_timer += delta
		if fire_timer >= fire_interval:
			fire_timer = 0.0
			fire_at(player)
	else:
		fire_timer = 0.0
	if not animations.is_playing():
		return
	var frame_duration := animations.sprite_frames.get_frame_duration(animations.animation, animations.frame)
	frame_progress += delta * absf(animations.get_playing_speed()) / frame_duration
	while frame_progress >= 0.25:
		frame_progress -= 0.25
		_move_step()

func _move_step() -> void:
	if (step_offset >= STEPS_FROM_CENTER and direction > 0) or (step_offset <= -STEPS_FROM_CENTER and direction < 0):
		direction = -direction
	var motion := Vector2(direction * STEP_DISTANCE, 0)
	if test_move(global_transform, motion):
		direction = -direction
		return
	move_and_collide(motion)
	step_offset += direction

func fire_at(player: Node2D) -> void:
	var fireball := FIREBALL.instantiate() as Node2D
	get_parent().add_child(fireball)
	fireball.global_position = global_position
	fireball.call("launch", self, player.global_position - global_position)

func receive_fireball_hit() -> void:
	if is_dying:
		return
	HIT_FLASH.apply(animations)
	hits += 1
	if hits >= 3:
		is_dying = true
		set_physics_process(false)
		set_deferred("collision_layer", 0)
		$ProjectileArea.set_deferred("collision_layer", 0)
		await get_tree().create_timer(HIT_FLASH.DURATION).timeout
		queue_free()

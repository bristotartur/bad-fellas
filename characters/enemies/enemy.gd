extends CharacterBody2D

const STEP_DISTANCE := 16.0
const SPRITE_SHEET := preload("res://assets/bone-worm-animations.png")

@export var step_duration := 0.25

@onready var contact_area: Area2D = $ContactArea
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var contacted_player: Node
var contact_time := 0.0
var movement_tween: Tween
var bypass_direction := Vector2.ZERO
var is_dying := false

func _ready() -> void:
	setup_animations()
	play_animation("idle")
	contact_area.body_entered.connect(_on_contact_body_entered)
	contact_area.body_exited.connect(_on_contact_body_exited)

func _physics_process(delta: float) -> void:
	if is_instance_valid(contacted_player):
		play_animation("attack")
		contact_time += delta
		if contact_time >= 1.0:
			contact_time -= 1.0
			contacted_player.call("take_damage", 1)
		return

	contacted_player = null
	contact_time = 0.0
	if movement_tween != null and movement_tween.is_running():
		return

	var players := get_tree().get_nodes_in_group("player")
	if players.is_empty():
		play_animation("idle")
		return

	var player := players[0] as CharacterBody2D
	if player == null or player.get_parent() != get_parent():
		play_animation("idle")
		return

	var direction := get_chase_direction(player.global_position - global_position)
	if direction == Vector2.ZERO:
		play_animation("idle")
		return

	var motion := direction * STEP_DISTANCE
	if test_move(global_transform, motion):
		play_animation("idle")
		return

	play_animation("walk", direction)
	movement_tween = create_tween()
	movement_tween.tween_property(self, "global_position", global_position + motion, step_duration)

func get_chase_direction(offset: Vector2) -> Vector2:
	var horizontal := Vector2(signf(offset.x), 0.0)
	var vertical := Vector2(0.0, signf(offset.y))
	var primary := horizontal if absf(offset.x) >= absf(offset.y) else vertical
	var secondary := vertical if primary == horizontal else horizontal

	if primary == Vector2.ZERO:
		return Vector2.ZERO

	if not test_move(global_transform, primary * STEP_DISTANCE):
		bypass_direction = Vector2.ZERO
		return primary

	if bypass_direction != Vector2.ZERO and not test_move(
		global_transform,
		bypass_direction * STEP_DISTANCE
	):
		return bypass_direction
	bypass_direction = Vector2.ZERO

	if secondary != Vector2.ZERO and not test_move(global_transform, secondary * STEP_DISTANCE):
		bypass_direction = secondary
		return secondary

	# ponytail: local wall-following handles simple obstacles; use grid pathfinding if rooms become maze-like.
	var side := Vector2(-primary.y, primary.x)
	var other_side := -side
	if offset.dot(other_side) > offset.dot(side):
		var swap := side
		side = other_side
		other_side = swap

	for direction in [side, other_side, -primary]:
		if not test_move(global_transform, direction * STEP_DISTANCE):
			if direction == side or direction == other_side:
				bypass_direction = direction
			return direction
	return Vector2.ZERO

func setup_animations() -> void:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	var frame_size := SPRITE_SHEET.get_size() / 4.0
	var names := ["idle", "walk", "attack", "hurt"]
	var speeds := [4.0, 8.0, 4.0, 12.0]
	for row in range(4):
		frames.add_animation(names[row])
		frames.set_animation_speed(names[row], speeds[row])
		frames.set_animation_loop(names[row], names[row] != "hurt")
		for column in range(4):
			var texture := AtlasTexture.new()
			texture.atlas = SPRITE_SHEET
			texture.region = Rect2(Vector2(column, row) * frame_size, frame_size)
			frames.add_frame(names[row], texture)
	sprite.sprite_frames = frames
	sprite.scale = Vector2.ONE * (48.0 / frame_size.x)

func play_animation(action: String, direction: Vector2 = Vector2.ZERO) -> void:
	if direction.x != 0:
		sprite.flip_h = direction.x < 0
	sprite.play(action)

func receive_sword_hit() -> void:
	if is_dying:
		return
	is_dying = true
	set_physics_process(false)
	if movement_tween != null:
		movement_tween.kill()
	set_deferred("collision_layer", 0)
	contact_area.set_deferred("monitoring", false)
	play_animation("hurt")
	await sprite.animation_finished
	queue_free()

func _on_contact_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		contacted_player = body
		contact_time = 0.0

func _on_contact_body_exited(body: Node2D) -> void:
	if body == contacted_player:
		contacted_player = null
		contact_time = 0.0

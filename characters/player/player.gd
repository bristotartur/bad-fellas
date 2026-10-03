extends CharacterBody2D

const TILE_SIZE     := 32.0
const MOVE_DISTANCE := TILE_SIZE / 2.0

@export var move_duration   := 0.14
@export var animation_speed := 1.6
@export var sprite_scale    := 1.25

var is_moving        := false
var is_attacking     := false
var facing_direction := Vector2.RIGHT
var controls_enabled := true
var movement_tween: Tween
var has_hit_target := false

@onready var attack_area: Area2D = $AttackArea
@onready var health_label: Label = $HUD/HealthPanel/HealthLabel

func _ready() -> void:
	add_to_group("player")
	$AnimatedSprite2D.scale = Vector2(sprite_scale, sprite_scale)
	$AnimatedSprite2D.speed_scale = animation_speed
	attack_area.body_entered.connect(_on_attack_area_body_entered)
	GameState.health_changed.connect(_update_health_label)
	_update_health_label(GameState.health, GameState.MAX_HEALTH)

func _physics_process(delta: float) -> void:
	if not controls_enabled or is_moving or is_attacking: return

	if Input.is_action_just_pressed("attack"):
		attack()
		return
	
	var direction := get_input_direction()
	if direction == Vector2.ZERO:
		play_idle_animation()
	else:
		move(direction)

func get_input_direction() -> Vector2:
	if Input.is_action_just_pressed("move_right"):
		return Vector2.RIGHT
	elif Input.is_action_just_pressed("move_left"):
		return Vector2.LEFT
	elif Input.is_action_just_pressed("move_up"):
		return Vector2.UP
	elif Input.is_action_just_pressed("move_down"):
		return Vector2.DOWN
	
	if Input.is_action_pressed("move_right"):
		return Vector2.RIGHT
	elif Input.is_action_pressed("move_left"):
		return Vector2.LEFT
	elif Input.is_action_pressed("move_up"):
		return Vector2.UP
	elif Input.is_action_pressed("move_down"):
		return Vector2.DOWN
		
	return Vector2.ZERO

func move(direction: Vector2) -> void:
	facing_direction = direction
	
	var motion := direction * MOVE_DISTANCE
	if test_move(global_transform, motion) and not can_cross_open_door(motion):
		return
		
	is_moving = true
	play_walk_animation(direction)
	
	var target_position := global_position + direction * MOVE_DISTANCE
	movement_tween = create_tween()
	movement_tween.tween_property(self, "global_position", target_position, move_duration)
	
	await movement_tween.finished
	is_moving = false
	movement_tween = null

func attack() -> void:
	is_attacking = true
	has_hit_target = false
	play_walk_animation(facing_direction)
	attack_area.position = facing_direction * (MOVE_DISTANCE + 4.0)
	attack_area.set_deferred("monitoring", true)

	var start_position := global_position
	var target_position := start_position + facing_direction * MOVE_DISTANCE
	if test_move(global_transform, facing_direction * MOVE_DISTANCE):
		target_position = start_position

	var attack_tween := create_tween()
	attack_tween.tween_property(self, "global_position", target_position, move_duration / 2.0)
	attack_tween.tween_property(self, "global_position", start_position, move_duration / 2.0)
	await attack_tween.finished

	attack_area.set_deferred("monitoring", false)
	is_attacking = false
	play_idle_animation()

func take_damage(amount: int) -> void:
	GameState.take_damage(amount)

func _on_attack_area_body_entered(body: Node2D) -> void:
	if not has_hit_target and body.has_method("receive_sword_hit"):
		has_hit_target = true
		body.call("receive_sword_hit")

func _update_health_label(current: int, maximum: int) -> void:
	health_label.text = "Vida: %d/%d" % [current, maximum]

func set_controls_enabled(enabled: bool) -> void:
	controls_enabled = enabled
	if not enabled and movement_tween:
		movement_tween.kill()
		movement_tween = null
		is_moving = false

func can_cross_open_door(motion: Vector2) -> bool:
	for door in get_tree().get_nodes_in_group("doors"):
		if door.has_method("accepts_player_motion") and door.call("accepts_player_motion", self, motion):
			return true
	return false

func play_walk_animation(direction: Vector2) -> void:
	if direction == Vector2.RIGHT:
		$AnimatedSprite2D.play("walking_sideways")
		$AnimatedSprite2D.flip_h = false
	elif direction == Vector2.LEFT:
		$AnimatedSprite2D.play("walking_sideways")
		$AnimatedSprite2D.flip_h = true
	elif direction == Vector2.UP:
		$AnimatedSprite2D.play("walking_up")
		$AnimatedSprite2D.flip_h = false
	elif direction == Vector2.DOWN:
		$AnimatedSprite2D.play("walking_down")
		$AnimatedSprite2D.flip_h = false

func play_idle_animation() -> void:
	if facing_direction == Vector2.RIGHT:
		$AnimatedSprite2D.play("idle_side")
		$AnimatedSprite2D.flip_h = false
	elif facing_direction == Vector2.LEFT:
		$AnimatedSprite2D.play("idle_side")
		$AnimatedSprite2D.flip_h = true
	elif facing_direction == Vector2.UP:
		$AnimatedSprite2D.play("idle_up")
		$AnimatedSprite2D.flip_h = false
	elif facing_direction == Vector2.DOWN:
		$AnimatedSprite2D.play("idle_down")
		$AnimatedSprite2D.flip_h = false

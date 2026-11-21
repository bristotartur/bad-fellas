extends CharacterBody2D

const TILE_SIZE     := 32.0
const MOVE_DISTANCE := TILE_SIZE / 2.0
const COLLISION_PROBE_EPSILON := 0.01
const HIT_FLASH := preload("res://characters/hit_flash.gd")

@export var move_duration   := 0.14
@export var animation_speed := 1.6
@export var sprite_scale    := 1.25
@export var turn_delay      := 0.15

var is_moving        := false
var is_attacking     := false
var facing_direction := Vector2.RIGHT
var controls_enabled := true
var attack_blocked_until_release := false
var event_frozen := false
var animation_was_playing := false
var movement_tween: Tween
var has_hit_target := false
var turn_time_remaining := 0.0
var step_just_finished := false

@onready var attack_area: Area2D = $AttackArea
@onready var health_label: Label = $HUD/HealthPanel/HealthLabel

func _ready() -> void:
	add_to_group("player")
	$Animations.scale = Vector2(sprite_scale, sprite_scale)
	$Animations.speed_scale = animation_speed
	attack_area.body_entered.connect(_on_attack_area_body_entered)
	GameState.health_changed.connect(_update_health_label)
	_update_health_label(GameState.health, GameState.MAX_HEALTH)

func _physics_process(delta: float) -> void:
	if attack_blocked_until_release and not Input.is_action_pressed("attack"):
		attack_blocked_until_release = false
	if not controls_enabled or event_frozen or is_attacking:
		step_just_finished = false
		return
	if Input.is_action_pressed("block"):
		step_just_finished = false
		if movement_tween != null and movement_tween.is_valid():
			movement_tween.pause()
		play_block_animation()
		return
	if movement_tween != null and movement_tween.is_valid() and is_moving:
		movement_tween.play()
		play_walk_animation(facing_direction)
		return
	if is_moving:
		return
	if attack_blocked_until_release and Input.is_action_just_pressed("attack"):
		return
	# The interact action shares the attack button; while dialogue is open it
	# must not also start the attack animation.
	if Input.is_action_just_pressed("attack") and _is_dialogue_interaction():
		return

	if Input.is_action_just_pressed("attack"):
		attack()
		return
	
	var direction := get_input_direction()
	var continuing_movement := step_just_finished
	step_just_finished = false
	if direction == Vector2.ZERO:
		turn_time_remaining = 0.0
		play_idle_animation()
		return
	if direction != facing_direction:
		facing_direction = direction
		if not continuing_movement:
			turn_time_remaining = turn_delay
			play_idle_animation()
			return
		turn_time_remaining = 0.0
	if turn_time_remaining > 0.0:
		turn_time_remaining = maxf(0.0, turn_time_remaining - delta)
		if turn_time_remaining > 0.0:
			return
	move(direction)

func _is_dialogue_interaction() -> bool:
	var textbox := get_tree().get_first_node_in_group("textbox")
	if textbox is CanvasLayer and textbox.visible:
		return true
	return _get_nearby_interactable() != null

func _get_nearby_interactable() -> Node2D:
	for npc in get_tree().get_nodes_in_group("interactable_npcs"):
		if npc is Node2D and global_position.distance_to(npc.global_position) <= 64.0:
			return npc
	return null

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
	var collision := KinematicCollision2D.new()
	# A full-length probe reports contact with the next tile as a blockage,
	# even when the player would only touch its edge at the end of the step.
	var probe := direction * (MOVE_DISTANCE - COLLISION_PROBE_EPSILON)
	if test_move(global_transform, probe, collision, 0.0):
		if can_cross_open_door(motion):
			pass
		else:
			var collider := collision.get_collider() as Node
			if (
				collider == null
				or not collider.has_method("try_push")
				or not collider.call("try_push", direction)
			):
				return
		
	is_moving = true
	play_walk_animation(direction)
	
	var target_position := global_position + direction * MOVE_DISTANCE
	movement_tween = create_tween()
	movement_tween.tween_property(self, "global_position", target_position, move_duration)
	
	await movement_tween.finished
	is_moving = false
	movement_tween = null
	step_just_finished = true

func attack() -> void:
	is_attacking = true
	has_hit_target = false
	play_attack_animation()
	attack_area.position = facing_direction * (MOVE_DISTANCE + 4.0)
	attack_area.set_deferred("monitoring", true)

	await $Animations.animation_finished

	attack_area.set_deferred("monitoring", false)
	is_attacking = false
	play_idle_animation()

func take_damage(amount: int) -> void:
	if amount > 0 and GameState.health > 0:
		HIT_FLASH.apply($Animations)
	GameState.take_damage(amount)

func can_deflect_fireball(projectile_position: Vector2) -> bool:
	return controls_enabled and not event_frozen and not is_attacking and Input.is_action_pressed("block") and facing_direction.dot(projectile_position - global_position) > 0.0

func _on_attack_area_body_entered(body: Node2D) -> void:
	if not has_hit_target and body.has_method("receive_sword_hit"):
		has_hit_target = true
		body.call("receive_sword_hit")

func _update_health_label(current: int, maximum: int) -> void:
	health_label.text = "Vida: %d/%d" % [current, maximum]

func set_controls_enabled(enabled: bool) -> void:
	controls_enabled = enabled
	if not enabled or Input.is_action_pressed("attack"):
		attack_blocked_until_release = true
	if not enabled and movement_tween:
		movement_tween.kill()
		movement_tween = null
		is_moving = false
	if not enabled:
		var npc := _get_nearby_interactable()
		if npc != null:
			var toward_npc := npc.global_position - global_position
			if absf(toward_npc.x) > absf(toward_npc.y):
				facing_direction = Vector2.RIGHT if toward_npc.x > 0.0 else Vector2.LEFT
			else:
				facing_direction = Vector2.DOWN if toward_npc.y > 0.0 else Vector2.UP
		play_idle_animation()

func set_event_frozen(frozen: bool) -> void:
	if event_frozen == frozen:
		return
	event_frozen = frozen
	if movement_tween != null and movement_tween.is_valid():
		if frozen:
			movement_tween.pause()
		elif controls_enabled:
			movement_tween.play()
	if frozen:
		animation_was_playing = $Animations.is_playing()
		if animation_was_playing:
			$Animations.pause()
	elif animation_was_playing:
		$Animations.play()
		animation_was_playing = false

func can_cross_open_door(motion: Vector2) -> bool:
	for door in get_tree().get_nodes_in_group("doors"):
		if door.has_method("accepts_player_motion") and door.call("accepts_player_motion", self, motion):
			return true
	return false

func play_walk_animation(direction: Vector2) -> void:
	$Animations.flip_h = false
	if direction == Vector2.RIGHT:
		$Animations.play("walking_sideways")
	elif direction == Vector2.LEFT:
		$Animations.play("walking_sideways")
		$Animations.flip_h = true
	elif direction == Vector2.UP:
		$Animations.play("walking_up")
	elif direction == Vector2.DOWN:
		$Animations.play("walking_down")

func play_idle_animation() -> void:
	$Animations.flip_h = false
	if facing_direction == Vector2.RIGHT:
		$Animations.play("idle_side")
	elif facing_direction == Vector2.LEFT:
		$Animations.play("idle_side")
		$Animations.flip_h = true
	elif facing_direction == Vector2.UP:
		$Animations.play("idle_up")
	elif facing_direction == Vector2.DOWN:
		$Animations.play("idle_down")

func play_attack_animation() -> void:
	$Animations.flip_h = false
	if facing_direction == Vector2.RIGHT:
		$Animations.play("attacking_sideways")
	elif facing_direction == Vector2.LEFT:
		$Animations.play("attacking_sideways")
		$Animations.flip_h = true
	elif facing_direction == Vector2.UP:
		$Animations.play("attacking_up")
	elif facing_direction == Vector2.DOWN:
		$Animations.play("attacking_down")

func play_block_animation() -> void:
	$Animations.flip_h = facing_direction == Vector2.LEFT
	if facing_direction == Vector2.UP:
		$Animations.play("blocking_up")
	elif facing_direction == Vector2.DOWN:
		$Animations.play("blocking_down")
	else:
		$Animations.play("blocking_side")

func play_flute_animation() -> void:
	$Animations.flip_h = false
	$Animations.play("playing_flute")

func face_flute_teacher() -> void:
	$Animations.flip_h = false
	$Animations.play("idle_up")
	$Animations.stop()

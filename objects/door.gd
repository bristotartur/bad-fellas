extends Area2D

signal transition_requested(door: Area2D, player: CharacterBody2D)

enum DoorState {
	OPEN,
	CLOSED,
	LOCK
}

@onready var closed_area := $ClosedCollision/CollisionShape2D

@export var state := DoorState.OPEN
@export_node_path("Area2D") var destination_door: NodePath
@export var destination_phase: PackedScene

var is_player_inside := false
var player_inside: CharacterBody2D
var transition_is_requested := false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	$UnlockArea.body_entered.connect(_on_unlock_area_body_entered)

	update_collision()
	update_visual()

func _physics_process(_delta: float) -> void:
	if (
		transition_is_requested
		or state != DoorState.OPEN
		or (destination_door.is_empty() and destination_phase == null)
		or player_inside == null
	):
		return

	if is_player_fully_inside(player_inside):
		transition_is_requested = true
		if destination_phase != null:
			get_tree().call_deferred("change_scene_to_packed", destination_phase)
			return

		transition_requested.emit(self, player_inside)

func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D and body.is_in_group("player"):
		is_player_inside = true
		player_inside = body
		unlock_with_key()

func _on_body_exited(body: Node2D) -> void:
	if body is CharacterBody2D and body.is_in_group("player"):
		is_player_inside = false
		if body == player_inside:
			player_inside = null
			transition_is_requested = false

func _on_unlock_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		unlock_with_key()

func get_destination_door() -> Area2D:
	return get_node_or_null(destination_door) as Area2D

func get_exit_position() -> Vector2:
	return $SpawnPoint.global_position

func is_player_fully_inside(player: CharacterBody2D) -> bool:
	var player_collision := player.get_node_or_null("CollisionShape2D") as CollisionShape2D
	var player_shape := player_collision.shape as RectangleShape2D
	var trigger_shape := $TriggerArea.shape as RectangleShape2D
	if player_shape == null or trigger_shape == null:
		return false

	var trigger_transform: Transform2D = $TriggerArea.global_transform
	var player_transform: Transform2D = player_collision.global_transform
	var player_center: Vector2 = trigger_transform.affine_inverse() * player_collision.global_position
	var player_half_size := player_shape.size / 2.0
	var projected_half_size := _projected_half_extents(
		player_transform, trigger_transform, player_half_size
	)
	var trigger_half_size := trigger_shape.size / 2.0
	return (
		absf(player_center.x) + projected_half_size.x <= trigger_half_size.x
		and absf(player_center.y) + projected_half_size.y <= trigger_half_size.y
	)

func _projected_half_extents(
	player_transform: Transform2D,
	trigger_transform: Transform2D,
	player_half_size: Vector2
) -> Vector2:
	var axis_x := trigger_transform.x.normalized()
	var axis_y := trigger_transform.y.normalized()
	var player_x := player_transform.x.normalized()
	var player_y := player_transform.y.normalized()
	return Vector2(
		absf(axis_x.dot(player_x)) * player_half_size.x + absf(axis_x.dot(player_y)) * player_half_size.y,
		absf(axis_y.dot(player_x)) * player_half_size.x + absf(axis_y.dot(player_y)) * player_half_size.y
	)

func try_open() -> bool:
	if state == DoorState.LOCK:
		return false

	if state == DoorState.CLOSED:
		open()

	return true

func unlock_with_key() -> bool:
	if state != DoorState.LOCK or not GameState.hasKey:
		return false

	GameState.hasKey = false
	open()
	return true

func open() -> void:
	state = DoorState.OPEN
	update_collision()
	update_visual()

func accepts_player_motion(body: CharacterBody2D, motion: Vector2) -> bool:
	if state != DoorState.OPEN:
		return false

	var player_collision := body.get_node_or_null("CollisionShape2D") as CollisionShape2D
	var player_shape := player_collision.shape as RectangleShape2D
	var trigger_shape := $TriggerArea.shape as RectangleShape2D
	if player_shape == null or trigger_shape == null:
		return false

	var trigger_transform: Transform2D = $TriggerArea.global_transform
	var next_player_center: Vector2 = trigger_transform.affine_inverse() * (
		player_collision.global_position + motion
	)
	var player_transform: Transform2D = player_collision.global_transform
	var player_half_size := player_shape.size / 2.0
	var projected_half_size := _projected_half_extents(
		player_transform, trigger_transform, player_half_size
	)
	var trigger_half_size := trigger_shape.size / 2.0
	return (
		absf(next_player_center.x) + projected_half_size.x <= trigger_half_size.x
		and absf(next_player_center.y) <= trigger_half_size.y + projected_half_size.y
	)

func update_collision() -> void:
	var should_block := state != DoorState.OPEN
	closed_area.set_deferred("disabled", not should_block)

func update_visual() -> void:
	match state:
		DoorState.OPEN:
			$AnimatedSprite2D.play(&"open")
		DoorState.LOCK:
			$AnimatedSprite2D.play(&"lock")
		_:
			$AnimatedSprite2D.play(&"closed")

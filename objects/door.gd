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

	update_collision()
	update_visual()

func _physics_process(_delta: float) -> void:
	if (
		transition_is_requested
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
	if body is CharacterBody2D:
		is_player_inside = true
		player_inside = body

func _on_body_exited(body: Node2D) -> void:
	if body is CharacterBody2D:
		is_player_inside = false
		if body == player_inside:
			player_inside = null
			transition_is_requested = false

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

	var player_center: Vector2 = $TriggerArea.to_local(player_collision.global_position)
	var player_half_size := player_shape.size / 2.0
	var trigger_half_size := trigger_shape.size / 2.0
	return (
		abs(player_center.x) + player_half_size.x <= trigger_half_size.x
		and abs(player_center.y) + player_half_size.y <= trigger_half_size.y
	)

func try_open() -> bool:
	if state == DoorState.LOCK:
		return false

	if state == DoorState.CLOSED:
		state = DoorState.OPEN
		update_collision()
		update_visual()

	return true

func accepts_player_motion(body: CharacterBody2D, motion: Vector2) -> bool:
	if state != DoorState.OPEN:
		return false

	var player_collision := body.get_node_or_null("CollisionShape2D") as CollisionShape2D
	var player_shape := player_collision.shape as RectangleShape2D
	var trigger_shape := $TriggerArea.shape as RectangleShape2D
	if player_shape == null or trigger_shape == null:
		return false

	var next_player_center: Vector2 = $TriggerArea.to_local(
		player_collision.global_position + motion
	)
	var player_half_size := player_shape.size / 2.0
	var trigger_half_size := trigger_shape.size / 2.0
	return (
		abs(next_player_center.x) <= trigger_half_size.x + player_half_size.x
		and abs(next_player_center.y) <= trigger_half_size.y + player_half_size.y
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

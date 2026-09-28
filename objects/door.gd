extends Area2D

enum DoorState {
	OPEN,
	CLOSED,
	LOCK
}

@onready var closed_area := $ClosedCollision/CollisionShape2D

@export var state := DoorState.OPEN

var is_player_inside := false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	update_collision()
	update_visual()

func _process(_delta: float) -> void:
	if is_player_inside and Input.is_action_just_pressed("move_right"):
		print("Interact!")

func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		is_player_inside = true

func _on_body_exited(body: Node2D) -> void:
	if body is CharacterBody2D:
		is_player_inside = false

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

	var trigger_rect := Rect2(
		$TriggerArea.global_position - trigger_shape.size / 2.0,
		trigger_shape.size
	)
	var player_center := body.global_position + motion + player_collision.position
	var player_rect := Rect2(
		player_center - player_shape.size / 2.0,
		player_shape.size
	)
	return trigger_rect.intersects(player_rect)

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

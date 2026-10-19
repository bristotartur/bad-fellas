extends Node2D

signal room_entered(room: Node2D)

const VIEWPORT_SIZE := Vector2(640, 480)

@export var room_transition_duration := 1.6

@onready var camera: Camera2D = $Camera2D
@onready var room_a: Node2D = $RoomA

var is_transitioning := false

func _ready() -> void:
	camera.global_position = get_room_center(room_a)
	for door in get_tree().get_nodes_in_group("doors"):
		if door.has_signal("transition_requested"):
			door.connect("transition_requested", _on_door_transition_requested)

	room_entered.emit(room_a)

func _on_door_transition_requested(source_door: Area2D, player: CharacterBody2D) -> void:
	if is_transitioning:
		return

	var destination_door := source_door.call("get_destination_door") as Area2D
	if destination_door == null:
		return

	var destination_room := destination_door.get_parent() as Node2D
	if destination_room == null:
		return

	transition_player(player, destination_door, destination_room)

func transition_player(
	player: CharacterBody2D,
	destination_door: Area2D,
	destination_room: Node2D
) -> void:
	is_transitioning = true
	player.call("set_controls_enabled", false)
	player.visible = false

	var camera_tween := create_tween()
	camera_tween.set_trans(Tween.TRANS_LINEAR)
	camera_tween.tween_property(
		camera,
		"global_position",
		get_room_center(destination_room),
		room_transition_duration
	)
	await camera_tween.finished

	player.reparent(destination_room, true)
	player.global_position = destination_door.call("get_exit_position")
	player.visible = true
	player.call("set_controls_enabled", true)
	is_transitioning = false
	room_entered.emit(destination_room)

func get_room_center(room: Node2D) -> Vector2:
	return room.to_global(VIEWPORT_SIZE / 2.0)

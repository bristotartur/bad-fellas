extends CharacterBody2D

enum Side {
	FRONT,
	BACK,
	LEFT,
	RIGHT
}

const MOVE_DISTANCE := 16.0
const CARPET_TERRAIN := 2

@export var move_duration := 0.14
@export var side := Side.FRONT

var is_moving := false
var is_player_near := false
var laser_busy := false
var tile_map: TileMapLayer
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	set_sprite()

	var scene_root: Node = self
	while scene_root.get_parent() != null and scene_root.get_parent() != get_tree().root:
		scene_root = scene_root.get_parent()

	for node in scene_root.find_children("*", "TileMapLayer", true, false):
		var candidate := node as TileMapLayer
		var cell := candidate.local_to_map(candidate.to_local(collision_shape.global_position))
		var tile_data := candidate.get_cell_tile_data(cell)
		if tile_data != null and tile_data.get_custom_data("terrain") == CARPET_TERRAIN:
			tile_map = candidate
			break

	if tile_map == null:
		push_warning("O espelho não encontrou carpet sob sua base.")

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("interact") && is_player_near and not laser_busy:
		rotateSide()
		set_sprite()

func try_push(direction: Vector2) -> bool:
	if is_moving or laser_busy or not _can_move_on_carpet(direction):
		return false

	var motion := direction * MOVE_DISTANCE
	if test_move(global_transform, motion):
		return false

	is_moving = true
	var tween := create_tween()
	tween.tween_property(self, "global_position", global_position + motion, move_duration)
	tween.finished.connect(_on_move_finished)
	return true

func _can_move_on_carpet(direction: Vector2) -> bool:
	if tile_map == null:
		return false

	var rectangle := collision_shape.shape as RectangleShape2D
	if rectangle == null:
		return false

	var half_size := rectangle.size / 2.0
	var footprint: Array[Vector2] = [
		Vector2.ZERO,
		Vector2(-half_size.x, -half_size.y),
		Vector2(half_size.x, -half_size.y),
		Vector2(-half_size.x, half_size.y),
		Vector2(half_size.x, half_size.y),
	]

	var step_fractions: Array[float] = [0.0, 0.5, 1.0]
	for step_fraction in step_fractions:
		for point in footprint:
			var sample_position: Vector2 = collision_shape.to_global(point) + direction * MOVE_DISTANCE * step_fraction
			var cell := tile_map.local_to_map(tile_map.to_local(sample_position))
			var tile_data := tile_map.get_cell_tile_data(cell)
			if tile_data == null or tile_data.get_custom_data("terrain") != CARPET_TERRAIN:
				return false

	return true

func _on_move_finished() -> void:
	is_moving = false

func get_laser_point() -> Vector2:
	return collision_shape.global_position

func reflect_laser(incoming_direction: Vector2) -> Vector2:
	# FRONT looks down; BACK looks up. Either accepts light from the side.
	match side:
		Side.FRONT:
			return Vector2.ZERO if incoming_direction == Vector2.DOWN else Vector2.DOWN
		Side.BACK:
			return Vector2.ZERO if incoming_direction == Vector2.UP else Vector2.UP
		Side.LEFT:
			return Vector2.LEFT
		Side.RIGHT:
			return Vector2.RIGHT
	return Vector2.ZERO

func rotateSide() -> void:
	match side:
		Side.FRONT:
			side = Side.LEFT
		Side.LEFT:
			side = Side.BACK
		Side.BACK:
			side = Side.RIGHT
		Side.RIGHT:
			side = Side.FRONT
	set_sprite()

func set_sprite() -> void:
	$AnimatedSprite2D.flip_h = false
	match side:
		Side.FRONT:
			$AnimatedSprite2D.animation = "front"
		Side.BACK:
			$AnimatedSprite2D.animation = "back"
		Side.LEFT, Side.RIGHT:
			$AnimatedSprite2D.animation = "side"
			$AnimatedSprite2D.flip_h = side == Side.LEFT

func _on_interaction_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		is_player_near = true

func _on_interaction_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		is_player_near = false

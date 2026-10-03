extends Node2D

const ENEMY_SCENES := [
	preload("res://characters/enemies/enemy.tscn"),
	preload("res://characters/enemies/bat.tscn"),
]
const MIN_PLAYER_DISTANCE := 96.0
const GROUND_TERRAIN := 1

func _ready() -> void:
	call_deferred("spawn_enemy")

func spawn_enemy() -> void:
	await get_tree().physics_frame
	var room := get_parent()
	var tile_map := room.get_node_or_null("TileMapLayer") as TileMapLayer
	if tile_map == null or tile_map.tile_set == null:
		return

	var cells := tile_map.get_used_cells()
	cells.shuffle()
	var players := get_tree().get_nodes_in_group("player")
	var player: Node2D = players[0] if not players.is_empty() else null
	var enemy_scene: PackedScene = ENEMY_SCENES.pick_random()
	var enemy := enemy_scene.instantiate() as CharacterBody2D
	var query := PhysicsShapeQueryParameters2D.new()
	var spawn_shape := RectangleShape2D.new()
	spawn_shape.size = Vector2(32, 32)
	query.shape = spawn_shape
	query.collision_mask = enemy.collision_mask | 1 | 4
	query.collide_with_areas = true
	query.collide_with_bodies = true

	for cell in cells:
		var tile_data := tile_map.get_cell_tile_data(cell)
		if tile_data == null or tile_data.get_custom_data("terrain") != GROUND_TERRAIN:
			continue
		var candidate := tile_map.to_global(tile_map.map_to_local(cell))
		if player != null and candidate.distance_to(player.global_position) < MIN_PLAYER_DISTANCE:
			continue

		query.transform = Transform2D(0.0, candidate)
		if not get_world_2d().direct_space_state.intersect_shape(query, 1).is_empty():
			continue

		room.add_child(enemy)
		enemy.global_position = candidate
		return

	enemy.queue_free()
	push_warning("Não foi possível encontrar uma posição livre para o inimigo em %s." % room.name)

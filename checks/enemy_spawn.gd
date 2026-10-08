extends SceneTree

const PHASES := [
	"res://phases/phase_a/phase_a.tscn",
	"res://phases/phase_b/phase_b.tscn",
	"res://phases/phase_c/phase_c.tscn",
]

func _initialize() -> void:
	call_deferred("check_spawns")

func check_spawns() -> void:
	var checked := 0
	for iteration in range(5):
		for path in PHASES:
			var phase := load(path).instantiate() as Node2D
			phase.process_mode = Node.PROCESS_MODE_DISABLED
			root.add_child(phase)
			for frame in range(4):
				await physics_frame
			for room in phase.get_children():
				if not str(room.name).begins_with("Room"):
					continue
				var enemies: Array[CharacterBody2D] = []
				for child in room.get_children():
					if child is CharacterBody2D and child.has_method("receive_sword_hit"):
						enemies.append(child)
				if enemies.size() != 2:
					fail("Quantidade incorreta de inimigos: %s/%s" % [path, room.name])
					return
				if enemies[0].global_position.distance_to(enemies[1].global_position) < 48.0:
					fail("Inimigos muito próximos: %s/%s" % [path, room.name])
					return
				var tile_map := room.get_node("TileMapLayer") as TileMapLayer
				for enemy in enemies:
					var cell := tile_map.local_to_map(tile_map.to_local(enemy.global_position))
					var tile_data := tile_map.get_cell_tile_data(cell)
					if tile_data == null or tile_data.get_custom_data("terrain") != 1:
						fail("Inimigo fora do chão: %s/%s" % [path, room.name])
						return
					var shape := RectangleShape2D.new()
					shape.size = Vector2(32, 32)
					var query := PhysicsShapeQueryParameters2D.new()
					query.shape = shape
					query.transform = Transform2D(0, enemy.global_position)
					query.collision_mask = enemy.collision_mask | 1 | 4
					query.collide_with_areas = true
					if not phase.get_world_2d().direct_space_state.intersect_shape(query, 1).is_empty():
						fail("Inimigo sobre obstáculo/porta: %s/%s" % [path, room.name])
						return
					checked += 1
			phase.free()
			await physics_frame
	print("OK: %d nascimentos em chão livre, sem portas ou obstáculos." % checked)
	quit()

func fail(message: String) -> void:
	push_error(message)
	quit(1)

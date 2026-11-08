extends Area2D

@export var speed := 180.0
@export var damage := 1

var direction := Vector2.ZERO
var caster: Node2D
var reflected := false

func launch(source: Node2D, aim: Vector2) -> void:
	caster = source
	direction = aim.normalized()

func _physics_process(delta: float) -> void:
	if direction == Vector2.ZERO:
		return
	var destination := global_position + direction * speed * delta
	var query := PhysicsRayQueryParameters2D.create(global_position, destination, 2 | (8 if reflected else 1))
	query.collide_with_areas = reflected
	var excluded: Array[RID] = []
	while true:
		query.exclude = excluded
		var hit := get_world_2d().direct_space_state.intersect_ray(query)
		if hit.is_empty():
			global_position = destination
			return
		var target := hit["collider"] as Node
		if target is TileMapLayer:
			var tile_map := target as TileMapLayer
			# TileMapLayer can combine several cells into one physics body, so its
			# RID alone does not necessarily identify the tile the ray struck.
			var hit_point: Vector2 = hit["position"]
			var cell := tile_map.local_to_map(tile_map.to_local(hit_point + direction * 0.1))
			var tile := tile_map.get_cell_tile_data(cell)
			if tile != null and tile.get_custom_data("terrain") == 2:
				excluded.append(hit["rid"])
				continue
		if not reflected and target != null and target.is_in_group("player"):
			if target.call("can_deflect_fireball", global_position):
				reflected = true
				direction = (caster.global_position - target.global_position).normalized() if is_instance_valid(caster) else -direction
				global_position = hit["position"] + direction * 1.0
				return
			target.call("take_damage", damage)
		elif reflected and is_instance_valid(caster) and (target == caster or target.get_parent() == caster):
			caster.call("receive_fireball_hit")
		queue_free()
		return

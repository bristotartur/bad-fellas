extends Node2D

const TILE_DISTANCE := 32.0
const MAX_STEPS := 256
const LASER_MASK := 15 # Player, Scenario, Triggers and Enemies.

@export_range(0.05, 1.0, 0.01) var tile_duration := 0.14

@onready var lever: Area2D = $"../Lever"
@onready var emitter: Area2D = $"../WallEyeTrigger"
@onready var target: Area2D = $"../WallEyeTarget"
@onready var laser: Line2D = $Laser

var mirrors: Array[CharacterBody2D] = []
var active := false
var completed := false

func _ready() -> void:
	for child in get_parent().get_children():
		if child is CharacterBody2D and child.has_method("reflect_laser"):
			mirrors.append(child as CharacterBody2D)
	lever.connect("activated", _on_activated)
	laser.clear_points()

func _on_activated() -> void:
	if active or completed:
		return
	active = true
	for mirror in mirrors:
		mirror.set("laser_busy", true)
	emitter.call("set_eye_animation", &"wide_eyed")
	_run_laser()

func _run_laser() -> void:
	var current: Vector2 = emitter.call("get_laser_point")
	var direction := Vector2.UP
	var visited: Dictionary = {}
	var last_mirror: CharacterBody2D = null
	laser.add_point(to_local(current))
	laser.add_point(to_local(current))

	for _step in range(MAX_STEPS):
		var next_point := current + direction * TILE_DISTANCE
		var exclusions: Array[RID] = []
		if last_mirror != null:
			exclusions.append(last_mirror.get_rid())
		last_mirror = null
		var query := PhysicsRayQueryParameters2D.create(
			current + direction * 0.1, next_point, LASER_MASK, exclusions
		)
		query.collide_with_areas = false
		await get_tree().physics_frame
		var hit: Dictionary = get_world_2d().direct_space_state.intersect_ray(query)
		if hit.is_empty():
			await _animate_to(current, next_point)
			current = next_point
			continue

		var hit_position: Vector2 = hit["position"]
		var hit_point := Vector2(
			hit_position.x if direction.x != 0.0 else current.x,
			hit_position.y if direction.y != 0.0 else current.y
		)
		await _animate_to(current, hit_point)
		var collider := hit["collider"] as CollisionObject2D
		if collider == target.get_node("Receiver"):
			await _finish_success()
			return

		var mirror := collider as CharacterBody2D
		if mirror == null or not mirror.has_method("reflect_laser"):
			_finish_failure()
			return

		var key := "%d:%s" % [mirror.get_instance_id(), direction]
		if visited.has(key):
			_finish_failure()
			return
		visited[key] = true
		var outgoing: Vector2 = mirror.call("reflect_laser", direction)
		if outgoing == Vector2.ZERO:
			_finish_failure()
			return

		var mirror_point: Vector2 = mirror.call("get_laser_point")
		if direction.x != 0.0 and outgoing.y != 0.0:
			current = Vector2(mirror_point.x, current.y)
		elif direction.y != 0.0 and outgoing.x != 0.0:
			current = Vector2(current.x, mirror_point.y)
		else:
			current = hit_point
		laser.set_point_position(laser.get_point_count() - 1, to_local(current))
		laser.add_point(to_local(current))
		direction = outgoing
		last_mirror = mirror

	_finish_failure()

func _animate_to(start: Vector2, end: Vector2) -> void:
	var duration := start.distance_to(end) / TILE_DISTANCE * tile_duration
	var tween := create_tween()
	tween.tween_method(_set_laser_tip, start, end, duration)
	await tween.finished

func _set_laser_tip(point: Vector2) -> void:
	laser.set_point_position(laser.get_point_count() - 1, to_local(point))

func _finish_failure() -> void:
	laser.clear_points()
	emitter.call("set_eye_animation", &"open")
	target.call("set_eye_animation", &"open")
	for mirror in mirrors:
		mirror.set("laser_busy", false)
	active = false
	lever.call("rearm")

func _finish_success() -> void:
	completed = true
	laser.clear_points()
	emitter.call("set_eye_animation", &"open")
	target.call("set_eye_animation", &"wide_eyed")
	await get_tree().create_timer(1.0).timeout
	emitter.call("set_eye_animation", &"closed")
	target.call("set_eye_animation", &"closed")
	for mirror in mirrors:
		mirror.set("laser_busy", false)
	active = false
	lever.call("lock")

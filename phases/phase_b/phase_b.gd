extends "res://phases/phase_a/phase_a.gd"

const FLUTE_SAFE_DISTANCE := 64.0
const KNOCKBACK_DISTANCE := 64.0
const KNOCKBACK_DURATION := 0.35
const MAGE_SHAKE_PIXELS := 2
const MAGE_SHAKE_DURATION := 0.3

var flute: Area2D

func _ready() -> void:
	super._ready()
	flute = $RoomC.find_child("Flute", true, false) as Area2D
	if flute == null:
		push_warning("A sala C precisa de uma instância de Flute para a cutscene.")
		return
	if GameState.hasFlute:
		flute.queue_free()
		return
	flute.hide()
	flute.set_deferred("monitoring", false)
	$RoomC/Mage.defeated.connect(_on_mage_defeated)

func _on_mage_defeated() -> void:
	_shake_for_mage_defeat()
	if not is_instance_valid(flute):
		return
	var player := get_tree().get_first_node_in_group("player") as CharacterBody2D
	if player == null or player.get_parent() != $RoomC:
		flute.show()
		flute.set_deferred("monitoring", true)
		return
	player.call("set_controls_enabled", false)
	if player.global_position.distance_to(flute.global_position) <= FLUTE_SAFE_DISTANCE:
		player.set("facing_direction", Vector2.UP)
		player.call("play_idle_animation")
		var previous := [0.0]
		var tween := create_tween()
		tween.tween_method(func(distance: float) -> void:
			player.move_and_collide(Vector2.DOWN * (distance - previous[0]))
			previous[0] = distance
		, 0.0, KNOCKBACK_DISTANCE, KNOCKBACK_DURATION)
		await tween.finished
	flute.show()
	flute.set_deferred("monitoring", true)
	await get_tree().create_timer(0.5).timeout
	if is_instance_valid(player):
		player.call("set_controls_enabled", true)

func _shake_for_mage_defeat() -> void:
	camera_rest_offset = camera.offset
	camera_shake_pixels = MAGE_SHAKE_PIXELS
	camera_shaking = true
	await get_tree().create_timer(MAGE_SHAKE_DURATION).timeout
	camera_shaking = false
	camera.offset = camera_rest_offset
	camera_shake_pixels = CAMERA_SHAKE_PIXELS

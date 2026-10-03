extends Node

signal health_changed(current: int, maximum: int)

const MAX_HEALTH := 10
const INITIAL_SCENE := "res://phases/phase_a/phase_a.tscn"

var health := MAX_HEALTH

func take_damage(amount: int) -> void:
	if amount <= 0 or health <= 0:
		return

	health = maxi(health - amount, 0)
	health_changed.emit(health, MAX_HEALTH)
	if health == 0:
		call_deferred("restart_game")

func restart_game() -> void:
	health = MAX_HEALTH
	health_changed.emit(health, MAX_HEALTH)
	get_tree().change_scene_to_file(INITIAL_SCENE)

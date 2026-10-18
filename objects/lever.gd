extends Area2D

signal activated

enum LeverState {
	ON,
	OFF
}

@export var state  := LeverState.OFF
var is_player_near := false
var locked := false
var busy := false

func _ready() -> void:
	pass

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("interact") and is_player_near and not locked and not busy:
		set_state(LeverState.ON)
		busy = true
		activated.emit()

func rearm() -> void:
	busy = false
	set_state(LeverState.OFF)

func lock() -> void:
	locked = true
	busy = false

func set_state(state: LeverState) -> void:
	$Sprite2D.flip_h = state == LeverState.ON
	self.state = state

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		is_player_near = true

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		is_player_near = false

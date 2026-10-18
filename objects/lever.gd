extends Area2D

enum LeverState {
	ON,
	OFF
}

@export var state  := LeverState.OFF
var is_player_near := false

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("interact") && is_player_near:
		var new_state = LeverState.ON if state == LeverState.OFF else LeverState.OFF
		set_state(new_state)

func set_state(state: LeverState) -> void:
	$Sprite2D.flip_h = state == LeverState.ON
	self.state = state

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		is_player_near = true

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		is_player_near = false

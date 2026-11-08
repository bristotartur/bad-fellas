extends StaticBody2D

const INTERACTION_DISTANCE := 64.0
const DIALOGUE := "Zzz"

func _ready() -> void:
	add_to_group("interactable_npcs")

func _process(_delta: float) -> void:
	if not Input.is_action_just_pressed("interact"):
		return
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null or global_position.distance_to(player.global_position) > INTERACTION_DISTANCE:
		return
	var textbox := get_tree().get_first_node_in_group("textbox")
	if textbox == null:
		return
	if textbox.visible or textbox.interaction_frame == Engine.get_process_frames():
		return
	textbox.call("show_message", "Sapo Dorminhoco:", DIALOGUE)

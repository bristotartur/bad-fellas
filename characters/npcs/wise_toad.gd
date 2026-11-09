extends StaticBody2D

const DIALOGUE_1 := [
	"Aquele preguiçoso, meu neto está dormindo o dia inteiro.",
	"*ribbit*",
	"Entendo, você quer chegar ao próximo andar, *ribbit*, mas meu neto decidiu cochilar bem na frente da saída.",
	"Fuffuffu",
	"Se você me trouxer uma flauta, posso lhe ensinar sua a canção favorita para acordá-lo.",
	"*Ribbit*"
]
const DIALOGUE_2 := [
	"*ribbit*",
	"Traga uma flauta para que eu possa lhe ensinar como acordar meu neto."	
]

func _ready() -> void:
	add_to_group("interactable_npcs")

func _process(_delta: float) -> void:
	if not Input.is_action_just_pressed("interact"):
		return
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null or global_position.distance_to(player.global_position) > 64.0:
		return
	var textbox := get_tree().get_first_node_in_group("textbox")
	if textbox == null or textbox.visible or textbox.interaction_frame == Engine.get_process_frames():
		return
	var dialogue: Array = DIALOGUE_2 if GameState.met_wise_toad else DIALOGUE_1
	GameState.met_wise_toad = true
	textbox.call("show_dialogue", "Sapo Sabido:", dialogue)

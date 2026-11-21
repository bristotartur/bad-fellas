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
const FLUTE_INTRO := [
	"Vejo que você roubou a flauta daquela feiticeira",
	"*ribbit*",
	"Se prepare, você está prestes a presenciar a lírica do melhor barítono desta torre!",
	"Repita comigo..."
]
const AFTER_SONG := "Talvez devêssemos tocar algumas do Jethro Tull na próxima vez."

func _ready() -> void:
	add_to_group("interactable_npcs")

func _process(_delta: float) -> void:
	if not Input.is_action_just_pressed("interact"):
		return
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null or global_position.distance_to(player.global_position) > 64.0:
		return
	var textbox := get_tree().get_first_node_in_group("textbox")
	var minigame := get_tree().get_first_node_in_group("flute_minigame")
	if textbox == null or textbox.visible or textbox.interaction_frame == Engine.get_process_frames() or (minigame and minigame.flute_minigame_active):
		return
	if GameState.hasFlute:
		if GameState.completed_wise_toad_song:
			textbox.call("show_message", "Sapo Sabido:", AFTER_SONG)
		elif not GameState.heard_wise_toad_flute_intro:
			GameState.heard_wise_toad_flute_intro = true
			textbox.call("show_dialogue", "Sapo Sabido:", FLUTE_INTRO)
			await Signal(textbox, "dialogue_finished")
			if is_instance_valid(minigame) and is_inside_tree():
				minigame.call("start_flute_game")
		else:
			if minigame:
				minigame.call("start_flute_game")
		return
	var dialogue: Array = DIALOGUE_2 if GameState.met_wise_toad else DIALOGUE_1
	GameState.met_wise_toad = true
	textbox.call("show_dialogue", "Sapo Sabido:", dialogue)

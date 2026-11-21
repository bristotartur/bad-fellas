extends StaticBody2D

const INTERACTION_DISTANCE := 64.0
const PLAYER_SCRIPT := preload("res://characters/player/player.gd")
const DIALOGUE := "Zzz"
const WAKE_DIALOGUE := [
	"Eu amo essa música!",
	"*ribbit*",
	"Você é estranho..., o que faz aqui?",
	"...",
	"Ohh!",
	"Perdão por bloquear seu caminho.",
	"Vá em frente e consquiste sua princesa!",
	"*ribbit*",
]
const CLEAR_DOOR_STEPS := 4
const TOAD_STEP_DURATION_MULTIPLIER := 2.0
const WAIT_AFTER_SONG := 2.0 * 60.0 / 100.0

var waking_up := false

func _ready() -> void:
	add_to_group("interactable_npcs")
	if GameState.sleepy_toad_awake:
		position.x -= CLEAR_DOOR_STEPS * PLAYER_SCRIPT.MOVE_DISTANCE
		$Animations.play("awake")

func _process(_delta: float) -> void:
	if waking_up or GameState.sleepy_toad_awake or not Input.is_action_just_pressed("interact"):
		return
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null or global_position.distance_to(player.global_position) > INTERACTION_DISTANCE:
		return
	var textbox := get_tree().get_first_node_in_group("textbox")
	if textbox == null:
		return
	if textbox.visible or textbox.interaction_frame == Engine.get_process_frames():
		return
	if GameState.completed_wise_toad_song and GameState.hasFlute:
		var minigame := get_tree().get_first_node_in_group("flute_minigame")
		if minigame:
			_wake_with_song(player, textbox, minigame)
		return
	textbox.call("show_message", "Sapo Dorminhoco:", DIALOGUE)

func _wake_with_song(player: Node2D, textbox: Node, minigame: Node) -> void:
	waking_up = true
	player.call("set_controls_enabled", false)
	player.call("play_flute_animation")
	await minigame.call("play_learned_song")
	if not is_instance_valid(player):
		return
	$Animations.play("awake")
	await get_tree().create_timer(WAIT_AFTER_SONG).timeout
	if not is_instance_valid(player):
		return
	player.call("face_flute_teacher")
	textbox.set("restore_controls_on_close", false)
	textbox.call("show_dialogue", "Sapo Dorminhoco:", WAKE_DIALOGUE)
	player.call("face_flute_teacher")
	await Signal(textbox, "dialogue_finished")
	if not is_instance_valid(player):
		return
	var step_distance: float = PLAYER_SCRIPT.MOVE_DISTANCE
	var step_duration: float = player.get("move_duration") * TOAD_STEP_DURATION_MULTIPLIER
	for i in CLEAR_DOOR_STEPS:
		var tween := create_tween()
		tween.tween_property(self, "global_position", global_position + Vector2.LEFT * step_distance, step_duration)
		await tween.finished
	GameState.sleepy_toad_awake = true
	waking_up = false
	player.call("set_controls_enabled", true)

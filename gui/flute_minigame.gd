extends CanvasLayer

const FLUTE_NOTE := preload("res://gui/flute_note.gd")
const BEAT_SECONDS := 60.0 / 100.0
const MELODY_FREQUENCIES := [
	[261.63, 261.63, 392.00, 392.00, 440.00, 440.00, 392.00],
	[349.23, 349.23, 329.63, 329.63, 293.66, 293.66, 261.63],
]
const FLUTE_FAILURE_DIALOGUES := [
	"Fora do tom..., vamos outra vez",
	"Não tenha pressa..., vamos de novo",
	"Furando o tempo, normal para principiantes..., vamos mais uma vez",
]
const FLUTE_SUCCESS_DIALOGUE := [
	"Você até que leva jeito para música. Quem sabe um dia não fazemos uma *jam*...",
	"*ribbit*",
	"Fuffuffu",
	"Acorde aquele grandalhão e prossiga para o próximo piso!",
]

var flute_minigame_active := false
var flute_accepting_input := false
var flute_dialogue_active := false
var flute_sequence_index := 0
var flute_note_index := 0
var flute_run := 0
var flute_sounds: Array = []
var toad_sounds: Array = []
var flute_audio: AudioStreamPlayer


@onready var note_sequences: Array[Control] = [$NoteSequences/Sequence1, $NoteSequences/Sequence2]
@onready var textbox = get_tree().get_first_node_in_group("textbox")

func _ready() -> void:
	add_to_group("flute_minigame")
	visible = false
	flute_audio = AudioStreamPlayer.new()
	add_child(flute_audio)
	for sequence in MELODY_FREQUENCIES:
		var sounds: Array[AudioStreamWAV] = []
		var voice: Array[AudioStreamWAV] = []
		for frequency in sequence:
			sounds.append(_make_note_sound(frequency * 2.0))
			voice.append(_make_note_sound(frequency * 0.5, true))
		flute_sounds.append(sounds)
		toad_sounds.append(voice)

func _input(event: InputEvent) -> void:
	if flute_minigame_active and not flute_dialogue_active:
		_handle_flute_input(event)

func begin_flute_minigame() -> bool:
	if visible or not GameState.hasFlute:
		return false
	var player := get_tree().get_first_node_in_group("player")
	if player == null or not player.has_method("play_flute_animation"):
		return false
	flute_minigame_active = true
	for sequence in note_sequences:
		sequence.hide()
		for slot in sequence.get_children():
			if slot is FLUTE_NOTE:
				slot.set_correct(false)
	$NoteSequences.show()
	visible = true
	player.call("set_controls_enabled", false)
	player.call("face_flute_teacher")
	return true

# sequence_index é 0 ou 1. As direções são configuradas nos nós de notas.
func show_flute_notes(sequence_index: int) -> bool:
	if not flute_minigame_active or sequence_index < 0 or sequence_index >= note_sequences.size():
		return false
	for slot in note_sequences[sequence_index].get_children():
		if slot is FLUTE_NOTE:
			slot.set_correct(false)
	for i in note_sequences.size():
		note_sequences[i].visible = i == sequence_index
	return true

func _flute_notes(sequence_index: int) -> Array:
	var notes := note_sequences[sequence_index].get_children().filter(func(child: Node) -> bool: return child is FLUTE_NOTE)
	notes.sort_custom(func(a: Control, b: Control) -> bool: return a.position.x < b.position.x)
	return notes

func start_flute_game() -> void:
	if not begin_flute_minigame():
		return
	flute_sequence_index = 0
	flute_run += 1
	_play_flute_sequence(flute_run)

func _play_flute_sequence(run: int) -> void:
	flute_accepting_input = false
	flute_note_index = 0
	var player := get_tree().get_first_node_in_group("player")
	if player and player.has_method("face_flute_teacher"):
		player.call("face_flute_teacher")
	var notes := _flute_notes(flute_sequence_index)
	if notes.size() != MELODY_FREQUENCIES[flute_sequence_index].size():
		push_warning("A sequência da flauta precisa ter sete notas.")
		end_flute_minigame()
		return
	show_flute_notes(flute_sequence_index)
	for note in notes:
		note.hide()
	for i in notes.size():
		notes[i].show()
		_play_note_sound(flute_sequence_index, i, true)
		await get_tree().create_timer(BEAT_SECONDS).timeout
		if not flute_minigame_active or run != flute_run:
			return
	await get_tree().create_timer(BEAT_SECONDS * 2.0).timeout
	if not flute_minigame_active or run != flute_run:
		return
	for note in notes:
		note.hide()
	if is_instance_valid(player) and player.has_method("play_flute_animation"):
		player.call("play_flute_animation")
	flute_accepting_input = true

func _handle_flute_input(event: InputEvent) -> void:
	if not flute_accepting_input or not event is InputEventKey or not event.pressed or event.echo:
		return
	var direction := -1
	if event.is_action_pressed("move_up") or event.keycode == KEY_UP:
		direction = FLUTE_NOTE.Direction.UP
	elif event.is_action_pressed("move_right") or event.keycode == KEY_RIGHT:
		direction = FLUTE_NOTE.Direction.RIGHT
	elif event.is_action_pressed("move_left") or event.keycode == KEY_LEFT:
		direction = FLUTE_NOTE.Direction.LEFT
	elif event.is_action_pressed("move_down") or event.keycode == KEY_DOWN:
		direction = FLUTE_NOTE.Direction.DOWN
	if direction < 0:
		return
	get_viewport().set_input_as_handled()
	var notes := _flute_notes(flute_sequence_index)
	if direction != notes[flute_note_index].direction:
		_handle_flute_failure(flute_run)
		return
	_play_note_sound(flute_sequence_index, flute_note_index)
	var note = notes[flute_note_index]
	note.set_correct(true)
	note.show()
	flute_note_index += 1
	if flute_note_index == notes.size():
		_finish_flute_sequence(flute_run)

func _finish_flute_sequence(run: int) -> void:
	flute_accepting_input = false
	await get_tree().create_timer(BEAT_SECONDS * 2.0).timeout
	if not flute_minigame_active or run != flute_run:
		return
	flute_sequence_index += 1
	if flute_sequence_index < note_sequences.size():
		_play_flute_sequence(run)
	else:
		GameState.completed_wise_toad_song = true
		end_flute_minigame()
		textbox.show_dialogue("Sapo Sabido:", FLUTE_SUCCESS_DIALOGUE)

func _handle_flute_failure(run: int) -> void:
	flute_accepting_input = false
	var player := get_tree().get_first_node_in_group("player")
	if player and player.has_method("face_flute_teacher"):
		player.call("face_flute_teacher")
	await get_tree().create_timer(BEAT_SECONDS * 2.0).timeout
	if not flute_minigame_active or run != flute_run:
		return
	for sequence in note_sequences:
		sequence.hide()
	flute_dialogue_active = true
	visible = false
	textbox.restore_controls_on_close = false
	textbox.show_dialogue("Sapo Sabido:", [FLUTE_FAILURE_DIALOGUES.pick_random()])
	await textbox.dialogue_finished
	if not flute_minigame_active or run != flute_run:
		return
	flute_dialogue_active = false
	visible = true
	await get_tree().create_timer(BEAT_SECONDS * 2.0).timeout
	if flute_minigame_active and run == flute_run:
		_play_flute_sequence(run)

func _play_note_sound(sequence_index: int, note_index: int, toad := false) -> void:
	flute_audio.stream = toad_sounds[sequence_index][note_index] if toad else flute_sounds[sequence_index][note_index]
	flute_audio.play()

func play_learned_song() -> void:
	var beat := 60.0 / 112.0
	for sequence_index in MELODY_FREQUENCIES.size():
		var sequence: Array = MELODY_FREQUENCIES[sequence_index]
		for note_index in sequence.size():
			var duration := beat * 2.0 if sequence_index == 0 and note_index == 6 else beat
			flute_audio.stream = _make_note_sound(sequence[note_index] * 2.0, false, duration)
			flute_audio.play()
			await get_tree().create_timer(duration).timeout
	flute_audio.stop()

func _make_note_sound(frequency: float, voice := false, duration := BEAT_SECONDS) -> AudioStreamWAV:
	const SAMPLE_RATE := 22050
	var samples := PackedByteArray()
	var sample_count := int(SAMPLE_RATE * duration)
	samples.resize(sample_count * 2)
	var phase := 0.0
	for i in sample_count:
		var time := float(i) / SAMPLE_RATE
		var envelope := minf(1.0, minf(time / 0.02, (duration - time) / 0.05))
		var sample := sin(TAU * frequency * time)
		if voice:
			phase += TAU * frequency * (1.0 + 0.008 * sin(TAU * 5.2 * time)) / SAMPLE_RATE
			sample = 0.55 * sin(phase) + 0.26 * sin(phase * 2.0) + 0.13 * sin(phase * 3.0) + 0.06 * sin(phase * 4.0)
		var value := int(sample * envelope * 9000.0)
		samples.encode_s16(i * 2, value)
	var sound := AudioStreamWAV.new()
	sound.format = AudioStreamWAV.FORMAT_16_BITS
	sound.mix_rate = SAMPLE_RATE
	sound.data = samples
	return sound

# A lógica do minigame chama este método após confirmar o acerto da nota.
func mark_flute_note_correct(sequence_index: int, note_index: int) -> bool:
	if not flute_minigame_active or sequence_index < 0 or sequence_index >= note_sequences.size():
		return false
	var sequence := note_sequences[sequence_index]
	if not sequence.visible:
		return false
	var notes := _flute_notes(sequence_index)
	if note_index < 0 or note_index >= notes.size():
		return false
	notes[note_index].set_correct(true)
	return true

func end_flute_minigame() -> void:
	if not flute_minigame_active:
		return
	flute_minigame_active = false
	flute_accepting_input = false
	flute_run += 1
	flute_audio.stop()
	$NoteSequences.hide()
	visible = false
	var player := get_tree().get_first_node_in_group("player")
	if player and player.has_method("set_controls_enabled"):
		player.call("set_controls_enabled", true)
		player.call("play_idle_animation")

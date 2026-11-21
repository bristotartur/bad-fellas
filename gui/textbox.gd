extends CanvasLayer

signal dialogue_finished

@export var characters_per_second := 30.0

var revealed_characters := 0.0
var interaction_frame := -1
var dialogue_lines: Array = []
var dialogue_index := 0
var dialogue_speaker := ""
var restore_controls_on_close := true

@onready var speaker: Label = $Speaker
@onready var message: Label = $Message
@onready var message_top: float = $Message.offset_top

func _ready() -> void:
	add_to_group("textbox")
	visible = false

func _process(delta: float) -> void:
	if visible and message.visible_characters < message.get_total_character_count():
		revealed_characters += characters_per_second * delta
		message.visible_characters = mini(int(revealed_characters), message.get_total_character_count())

func _input(event: InputEvent) -> void:
	if not visible or not event.is_action_pressed("interact") or event.is_echo():
		return
	interaction_frame = Engine.get_process_frames()
	if message.visible_characters < message.get_total_character_count():
		message.visible_characters = message.get_total_character_count()
	elif dialogue_index + 1 < dialogue_lines.size():
		dialogue_index += 1
		_set_message(dialogue_speaker, dialogue_lines[dialogue_index])
	else:
		hide_message()
	get_viewport().set_input_as_handled()

func show_message(who: String, text: String) -> void:
	dialogue_lines.clear()
	_set_message(who, text)

func show_dialogue(who: String, lines: Array) -> void:
	if lines.is_empty():
		return
	dialogue_lines = lines.duplicate()
	dialogue_index = 0
	dialogue_speaker = who
	_set_message(who, dialogue_lines[0])

func _set_message(who: String, text: String) -> void:
	message.show()
	speaker.text = who
	speaker.visible = not who.is_empty()
	message.offset_top = message_top if speaker.visible else (speaker.offset_top + message_top) / 2.0
	message.text = text
	message.visible_characters = 0
	revealed_characters = 0.0
	visible = true
	var player := get_tree().get_first_node_in_group("player")
	if player and player.has_method("set_controls_enabled"):
		player.call("set_controls_enabled", false)

func hide_message() -> void:
	visible = false
	dialogue_lines.clear()
	var player := get_tree().get_first_node_in_group("player")
	if restore_controls_on_close and player and player.has_method("set_controls_enabled"):
		player.call("set_controls_enabled", true)
	restore_controls_on_close = true
	dialogue_finished.emit()

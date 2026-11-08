extends CanvasLayer

@export var characters_per_second := 30.0

var revealed_characters := 0.0
var interaction_frame := -1

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
	else:
		hide_message()
	get_viewport().set_input_as_handled()

func show_message(who: String, text: String) -> void:
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
	var player := get_tree().get_first_node_in_group("player")
	if player and player.has_method("set_controls_enabled"):
		player.call("set_controls_enabled", true)

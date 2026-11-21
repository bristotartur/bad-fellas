@tool
extends TextureRect

enum Direction { UP, RIGHT, LEFT, DOWN }

const NOTE_ATLAS := preload("res://assets/arrow_notes.png")

@export var direction: Direction = Direction.UP:
	set(value):
		direction = value
		_update_texture()

var correct := false

func _ready() -> void:
	_update_texture()

func set_correct(value: bool) -> void:
	correct = value
	_update_texture()

func _update_texture() -> void:
	var note_texture := AtlasTexture.new()
	note_texture.atlas = NOTE_ATLAS
	note_texture.region = Rect2(direction * 32, 32 if correct else 0, 32, 32)
	texture = note_texture

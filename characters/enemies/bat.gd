extends "res://characters/enemies/enemy.gd"

const BAT_FRAMES := preload("res://characters/enemies/bat_frames.tres")

var facing := "down"

func setup_animations() -> void:
	sprite.sprite_frames = BAT_FRAMES

func play_animation(action: String, direction: Vector2 = Vector2.ZERO) -> void:
	if direction != Vector2.ZERO:
		if absf(direction.x) >= absf(direction.y):
			facing = "right" if direction.x > 0 else "left"
		else:
			facing = "down" if direction.y > 0 else "up"
	var frame_width := 400.0 if facing == "down" else 256.0
	sprite.scale = Vector2.ONE * (48.0 / frame_width)
	sprite.flip_h = false
	sprite.play("%s_%s" % [action, facing])

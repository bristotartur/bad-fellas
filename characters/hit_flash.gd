extends RefCounted

const FLASH_SHADER := preload("res://characters/hit_flash.gdshader")
const DURATION := 0.15

static func apply(sprite: CanvasItem) -> void:
	var material: ShaderMaterial = sprite.get_meta("hit_flash_material", null)
	if material == null:
		material = ShaderMaterial.new()
		material.shader = FLASH_SHADER
		sprite.material = material
		sprite.set_meta("hit_flash_material", material)
	var previous: Tween = sprite.get_meta("hit_flash_tween", null)
	if previous != null and previous.is_valid():
		previous.kill()
	material.set_shader_parameter("flash_strength", 1.0)
	var tween := sprite.create_tween()
	tween.tween_interval(DURATION)
	tween.tween_callback(material.set_shader_parameter.bind("flash_strength", 0.0))
	sprite.set_meta("hit_flash_tween", tween)

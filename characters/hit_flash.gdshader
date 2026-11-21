shader_type canvas_item;

uniform float flash_strength = 0.0;

void fragment() {
	vec4 sprite_color = COLOR;
	sprite_color.rgb = mix(sprite_color.rgb, vec3(1.0), flash_strength);
	COLOR = sprite_color;
}

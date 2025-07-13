shader_type canvas_item;

uniform sampler2D overlay_tex: repeat_enable, filter_nearest;
uniform float scale = 0.00390625; // scale = pixels per unit / texture size
varying vec2 world_position;

void vertex(){
	// calculate the world position for use in the fragment shader
    world_position = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	vec2 uv = floor(world_position);
	// only apply overlay_tex on the fully red parts of the original tiles
	float mix_amount = floor(COLOR.r);

	// sample the overlay_tex using worldPos
	vec4 overlay_color = texture(overlay_tex, uv * scale);

	// combine original color and overlay color together
	COLOR = mix(COLOR, overlay_color, mix_amount);
}
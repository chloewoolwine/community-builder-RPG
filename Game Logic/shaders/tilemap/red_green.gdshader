shader_type canvas_item;

uniform sampler2D overlay_tex_red: repeat_enable, filter_nearest;
uniform sampler2D overlay_tex_green: repeat_enable, filter_nearest;
uniform float scale1 = 0.006944444; // calculated by 1/texture size e.g. 1/144
uniform float scale2 = 0.006944444; // calculated by 1/texture size e.g. 1/144
varying vec2 world_position;

void vertex(){
	// calculate the world position for use in the fragment shader
    world_position = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	// only apply overlay_tex on the fully red parts of the original tiles
	float mix_amount = floor(COLOR.r);
	vec4 overlay_color_1 = texture(overlay_tex_red, world_position * scale1);
	COLOR = mix(COLOR, overlay_color_1, mix_amount);

	mix_amount = floor(COLOR.g);
	vec4 overlay_color_2 = texture(overlay_tex_green, world_position * scale2);
	COLOR = mix(COLOR, overlay_color_2, mix_amount);
}
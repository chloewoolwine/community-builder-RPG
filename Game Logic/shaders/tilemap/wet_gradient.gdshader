shader_type canvas_item;

uniform sampler2D mod_color_tex: repeat_enable,filter_nearest;

uniform vec4 tint_color: source_color;
const float tile_size = 64.0;

//remove flat to add interpolation
varying flat vec2 vertex_pos;
uniform vec2 global_corner_pos;

void vertex() {
	//Change to global space coordinates from local space coordinates
	vertex_pos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	vec4 base_pixel = texture(TEXTURE, UV);
	vec2 relative_position = vertex_pos - global_corner_pos;
	int sample_x = int(floor((relative_position.x + tile_size / 2.0)/ tile_size));
	int sample_y = int(floor((relative_position.y + tile_size / 2.0)/ tile_size));
	float sample_value = texelFetch(mod_color_tex, ivec2(sample_x, sample_y), 0).a;
	//if (base_pixel.a > 0.){
		base_pixel = mix(base_pixel, tint_color, sample_value);
	//}
	COLOR = base_pixel;
}
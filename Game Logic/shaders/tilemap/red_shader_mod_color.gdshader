shader_type canvas_item;

uniform sampler2D overlay_tex: repeat_enable, filter_nearest;
uniform sampler2D mod_color_tex: repeat_enable, filter_nearest;
uniform vec4 img_color: source_color;
uniform float scale = 0.006944444; // calculated by 1/texture size e.g. 1/144
uniform float scale2 = .0010;
uniform vec2 tint_pos;
varying vec2 world_position;

void vertex(){
	// calculate the world position for use in the fragment shader
    world_position = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	// only apply overlay_tex on the fully red parts of the original tiles
	float red_mask = floor(COLOR.r);
	// sample the overlay_tex using worldPos
	vec4 overlay_color = texture(overlay_tex, world_position * scale);
	// combine original color and overlay color together
	COLOR = mix(COLOR, overlay_color, red_mask);

	// pixel at base
	vec4 base_pixel = COLOR;
	// pixel at mod color texture
	vec4 texture_pixel = texture(mod_color_tex, world_position * scale2);
	float color_weight = texture_pixel.a * img_color.a;
	// apply color to mod tex
	texture_pixel.rgb = vec3(img_color.rgb);
	//COLOR = base_pixel * texture_pixel;
	//texture_pixel.rgb = texture_pixel.rgb * color_weight;
	//vec3 a = mix(base_pixel.rgb, texture_pixel.rgb, color_weight);

	//COLOR.rgb = a;
	//COLOR.rgb = (base_pixel.rgb * (1.0 - color_weight)) + (a * color_weight);
	// mod base pixel with colored texture, keeping alpha in mind
	COLOR.rgb = mix(base_pixel.rgb, texture_pixel.rgb, texture_pixel.a * img_color.a);
}

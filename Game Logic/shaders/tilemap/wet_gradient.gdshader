shader_type canvas_item;

uniform sampler2D mod_color_tex: filter_nearest;

uniform vec4 tint_color: source_color;
const float tile_size = 64.0;

//remove flat to add interpolation
varying flat vec2 vertexPos;
uniform vec2 globalCornerPos;

void vertex() {
	//Change to global space coordinates from local space coordinates
	vertexPos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	float isWithinY = step(vertexPos.y, globalCornerPos.y) * step(globalCornerPos.y, vertexPos.y + (tile_size * 96.));
	float isWithinX = step(vertexPos.x, globalCornerPos.x) * step(globalCornerPos.x, vertexPos.x + (tile_size * 96.));
	float isWithin = isWithinY * isWithinX; // will be 1 when tile is highlighted
	
	vec4 textureColor = texture(TEXTURE, UV); 
	COLOR = mix(textureColor, vec4(0.8, 0.0, 0.0, 1.0), 1.0 * isWithin);
}
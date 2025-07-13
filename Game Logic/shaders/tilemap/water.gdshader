shader_type canvas_item;

uniform sampler2D bg : source_color;
uniform sampler2D wave1 : source_color, repeat_enable;
uniform sampler2D wave2 : source_color, repeat_enable;
uniform sampler2D noise : hint_default_black;

vec2 tile(vec2 _st, float _zoom){
  _st *= _zoom;
  return fract(_st);
}

float box(vec2 _st, vec2 _size){
  _size = vec2(0.5)-_size*0.5;
  vec2 uv = smoothstep(_size,_size+vec2(1e-4),_st);
  uv *= smoothstep(_size,_size+vec2(1e-4),vec2(1.0)-_st);
  return uv.x*uv.y;
}

varying vec2 world_position;
void vertex(){
	// calculate the world position for use in the fragment shader
    world_position = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment(){
	if(COLOR.r > .9) {
		vec2 st = vec2(UV.x/(SCREEN_PIXEL_SIZE.y/SCREEN_PIXEL_SIZE.x),UV.y);
		vec3 color = vec3(0.0);
		st = tile(st,8.0);
		color += texture(bg,st).rgb;
		color += 0.5* texture(wave1,vec2(st.x + TIME * 0.02,st.y +0.2 + sin(TIME*1.5) * 0.06)).rgb / 0.5 * texture(noise,vec2(st.x + cos(TIME * 0.5),st.y)).rgb;
		color += 0.5* texture(wave2,vec2(st.x - TIME * 0.08,st.y)).rgb / 0.5 * texture(noise,vec2(st.x ,st.y - sin(TIME * 0.5))).rgb;
		COLOR = vec4(color,1.0);
}}
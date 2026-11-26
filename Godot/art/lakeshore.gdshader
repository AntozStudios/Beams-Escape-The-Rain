shader_type spatial;
render_mode unshaded;
uniform vec4 deep : source_color = vec4(0.41,0.68,0.69,1.0);
uniform vec4 shallow : source_color = vec4(0.69,0.81,0.77,1.0);
uniform vec4 sand : source_color = vec4(0.92,0.89,0.81,1.0);
uniform vec4 dusk : source_color = vec4(0.81,0.65,0.69,1.0);
uniform float phase = 0.0;
varying vec2 lake;
void vertex() {
	lake = (MODEL_MATRIX * vec4(VERTEX,1.0)).xz;
}
void fragment() {
	float bend = sin(lake.y * 0.22 + phase);
	float bank = abs(lake.x - 1.9*bend) - (10.0 + 1.6*sin(lake.y*0.38));
	float shore = smoothstep(-2.4,0.0,bank);
	float wave = sin(lake.y*2.6 + lake.x*0.48 + bend - TIME*0.65);
	vec3 water = mix(deep.rgb,shallow.rgb,shore);
	water = mix(water,dusk.rgb,0.32*smoothstep(2.0,14.0,-lake.y));
	water += 0.026*smoothstep(0.86,1.0,wave)*(0.25+shore);
	ALBEDO = mix(water,sand.rgb,smoothstep(-0.08,0.1,bank));
}

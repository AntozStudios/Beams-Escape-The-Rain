shader_type spatial;
varying vec3 world_pos;
void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}
void fragment() {
	float ripple = sin(world_pos.z * 4.0 + sin(world_pos.x * 2.5) + TIME * 0.65);
	ALBEDO = mix(vec3(0.30,0.64,0.66), vec3(0.38,0.69,0.69), smoothstep(0.65,1.0,ripple));
	ROUGHNESS = 0.85;
}

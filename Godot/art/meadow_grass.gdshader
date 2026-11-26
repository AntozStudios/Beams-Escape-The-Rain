shader_type spatial;
render_mode cull_disabled, unshaded, world_vertex_coords;
uniform vec4 root_color : source_color = vec4(0.18,0.46,0.24,1.0);
uniform vec4 tip_color : source_color = vec4(0.58,0.82,0.39,1.0);
varying float height;
varying float patch_tint;

float hash(vec2 p) {
	return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);
}

float value_noise(vec2 p) {
	vec2 cell = floor(p);
	vec2 f = fract(p);
	f = f*f*(3.0-2.0*f);
	return mix(mix(hash(cell),hash(cell+vec2(1.0,0.0)),f.x),
		mix(hash(cell+vec2(0.0,1.0)),hash(cell+vec2(1.0,1.0)),f.x),f.y);
}

void vertex() {
	vec3 root = MODEL_MATRIX[3].xyz;
	height = clamp((VERTEX.y-root.y)*2.5,0.0,1.0);
	patch_tint = value_noise(root.xz*vec2(0.20,0.15));
	float gust = sin(dot(root.xz,vec2(0.72,0.32))-TIME*1.1);
	VERTEX.xz += vec2(0.11,0.04)*height*height*(0.45+gust);
}
void fragment() {
	vec3 deep_green = root_color.rgb*vec3(0.80,0.91,0.77);
	vec3 sunlit_green = root_color.rgb*vec3(1.22,1.13,0.82);
	vec3 root = mix(deep_green,sunlit_green,smoothstep(0.16,0.88,patch_tint));
	vec3 tip = mix(tip_color.rgb*vec3(0.88,1.0,0.77),tip_color.rgb*vec3(1.04,1.0,0.88),patch_tint);
	ALBEDO = mix(root,tip,height);
}

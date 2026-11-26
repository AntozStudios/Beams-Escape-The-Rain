shader_type spatial;
render_mode cull_disabled, unshaded, world_vertex_coords;
uniform vec4 root_color : source_color = vec4(0.22,0.47,0.29,1.0);
uniform vec4 tip_color : source_color = vec4(0.51,0.77,0.43,1.0);
varying float height;
void vertex() {
	vec3 root = MODEL_MATRIX[3].xyz;
	height = clamp((VERTEX.y-root.y)*2.5,0.0,1.0);
	float gust = sin(dot(root.xz,vec2(0.72,0.32))-TIME*1.1);
	VERTEX.xz += vec2(0.11,0.04)*height*height*(0.45+gust);
}
void fragment() {
	ALBEDO = mix(root_color.rgb,tip_color.rgb,height);
}

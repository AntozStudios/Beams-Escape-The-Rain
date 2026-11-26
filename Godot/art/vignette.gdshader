shader_type canvas_item;
uniform float intensity : hint_range(0.0, 0.5) = 0.5;
void fragment() {
	vec2 offset = (UV - 0.5) * 2.0;
	COLOR = vec4(0.32, 0.26, 0.43, smoothstep(0.22, 1.7, dot(offset, offset)) * intensity * 0.38);
}

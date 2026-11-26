shader_type canvas_item;
render_mode unshaded;
uniform vec4 upper : source_color;
uniform vec4 lower : source_color;
void fragment() {
	float wash = smoothstep(-0.12, 1.08, UV.y + 0.16 * (UV.x - 0.5));
	COLOR = vec4(mix(upper.rgb, lower.rgb, wash), 1.0);
}

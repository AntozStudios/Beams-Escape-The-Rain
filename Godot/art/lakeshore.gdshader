shader_type spatial;
render_mode unshaded;

uniform vec4 deep : source_color = vec4(0.16, 0.48, 0.72, 1.0);
uniform vec4 lagoon : source_color = vec4(0.18, 0.64, 0.79, 1.0);
uniform vec4 shallow : source_color = vec4(0.42, 0.79, 0.84, 1.0);
uniform vec4 sand : source_color = vec4(0.94, 0.91, 0.84, 1.0);
uniform vec4 wet_sand : source_color = vec4(0.77, 0.74, 0.66, 1.0);
uniform vec4 dune : source_color = vec4(0.88, 0.78, 0.64, 1.0);
uniform vec4 meadow : source_color = vec4(0.27, 0.60, 0.35, 1.0);
uniform vec4 meadow_light : source_color = vec4(0.44, 0.73, 0.42, 1.0);
uniform vec2 west_meadow;
uniform vec2 east_meadow;
uniform vec4 reflection : source_color = vec4(0.78, 0.66, 0.72, 1.0);
uniform vec4 foam : source_color = vec4(0.91, 0.98, 0.99, 1.0);
uniform vec2 islet_center;
uniform float phase = 0.0;
varying vec2 lake;

void vertex() {
	lake = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz;
}

// One short, soft brushstroke in selected cells, with staggered timing.
float glints(vec2 p) {
	vec2 grid = p * vec2(0.48, 1.35);
	grid.x += 0.5 * mod(floor(grid.y), 2.0);
	vec2 id = floor(grid);
	float seed = fract(sin(dot(id, vec2(41.7, 17.3))) * 1738.53);
	vec2 local = fract(grid) - 0.5;
	local.x -= 0.14 * sin(TIME * 0.38 + seed * 6.28);
	local.y -= (seed - 0.5) * 0.42;
	float stroke = length(local / vec2(0.10 + 0.12 * seed, 0.045));
	float aa = max(fwidth(stroke), 0.12);
	return (1.0 - smoothstep(1.0-aa, 1.0+aa, stroke))
		* smoothstep(0.56, 0.84, seed) * (0.55 + 0.45*sin(TIME*0.48 + seed*21.0));
}

vec3 beach_color(float inland, vec2 p, float aa) {
	float tide = inland + 0.16*sin(p.y*1.3+phase);
	vec3 beach = mix(wet_sand.rgb,sand.rgb,smoothstep(0.1,1.05,tide));
	float ridge = inland*1.12 + 1.5*sin(p.y*0.32+phase) + 0.38*sin(p.y*0.76);
	float dunes = smoothstep(0.10,0.85,cos(ridge));
	beach = mix(beach,dune.rgb,0.57*dunes*smoothstep(0.9,2.8,inland));

	vec2 radius = vec2(4.5,9.0);
	float border = min(length((p-west_meadow)/radius),length((p-east_meadow)/radius));
	border += 0.06*sin(p.y*1.1) + 0.04*sin(p.x*1.7+p.y*0.6);
	float cover = (1.0-smoothstep(0.99-aa*0.2,0.99+aa*0.2,border))*smoothstep(1.20-aa,1.20+aa,inland);
	float breeze = sin(dot(p,vec2(0.72,0.32))-TIME*1.1);
	vec3 grass = mix(meadow.rgb,meadow_light.rgb,0.42+0.2*sin(p.y*0.7)+0.08*breeze);
	return mix(beach,grass,cover);
}

void fragment() {
	float left = -8.8 + 2.7*sin(lake.y*0.21+phase) + 0.9*cos(lake.y*0.46);
	float right = 10.8 + 3.4*cos(lake.y*0.16-phase);
	float depth = min(lake.x-left, right-lake.x);
	float inlet = sin(lake.x*0.32 + lake.y*0.18 + phase);
	vec3 water = mix(lagoon.rgb, deep.rgb, smoothstep(1.0, 9.0, depth + inlet));
	water = mix(water, reflection.rgb, 0.24*smoothstep(0.0, 18.0, -lake.y + 2.5*inlet));
	water = mix(water, shallow.rgb, 0.78*(1.0-smoothstep(0.0, 2.1, depth)));

	// Broad swells drift through the bay; only short sections of each crest foam.
	float swell = lake.y*2.05 + lake.x*0.45 + 0.85*sin(lake.x*0.52+phase) - TIME*0.48;
	float crest = cos(swell);
	float breaks = smoothstep(-0.12,0.72,sin(lake.x*0.86 + 0.32*lake.y + phase));
	float crest_width = clamp(fwidth(swell)*0.18,0.012,0.07);
	float whitecap = smoothstep(0.92-crest_width,0.99,crest)*breaks;
	water = mix(water,lagoon.rgb,0.12*(1.0+crest));
	water = mix(water,foam.rgb,whitecap*mix(0.46,0.24,smoothstep(0.0,5.0,depth)));

	// A broken wash line beside the bank; keep the open water mostly quiet.
	float wash = depth - 0.24 - 0.09*sin(lake.y*1.4-TIME*0.55);
	float edge = max(fwidth(depth), 0.035);
	float lip = (1.0-smoothstep(0.045, 0.105+edge, abs(wash)))
		* smoothstep(-0.45, 0.45, sin(lake.y*0.89+phase));
	vec2 island = abs(lake-islet_center) - vec2(1.24, 1.45);
	float rim = length(max(island, vec2(0.0))) + min(max(island.x,island.y),0.0);
	float ring = (1.0-smoothstep(0.025,0.09+edge,abs(rim-0.43-0.07*sin(TIME*0.52))))
		* smoothstep(-0.4,0.8,inlet);
	water = mix(water,foam.rgb, max(max(lip*0.82,ring*0.64), glints(lake)*0.48));
	vec3 beach = beach_color(-depth,lake,max(fwidth(lake.x),fwidth(lake.y)));
	ALBEDO = mix(beach, water, smoothstep(-edge, edge, depth));
}

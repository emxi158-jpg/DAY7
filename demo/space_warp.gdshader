shader_type spatial;
render_mode world_vertex_coords, cull_disabled;

uniform float strength = 0.0;
uniform vec4 base_color : source_color = vec4(0.5);
uniform bool floor_tiles = false;
uniform bool anchored = false;
uniform vec3 anchor = vec3(0.0);
varying vec3 source_position;

vec3 warp(vec3 p) {
	vec3 compression = vec3(1.0 - 0.38 * strength, 1.0 - 0.20 * strength, 1.0 - 0.38 * strength);
	if (anchored) {
		p = anchor + (p - anchor) / compression;
	}
	float bend = strength * 0.65;
	float depth = clamp((5.0 - p.z) / 10.0, 0.0, 1.0);
	return vec3(
		p.x * (1.0 - bend * 0.20 * depth) + bend * (0.40 * p.y * (0.25 + 0.75 * depth) + 0.18 * p.z * depth),
		p.y * (1.0 - bend * 0.14 * depth) + bend * (-0.20 * p.x * depth + 0.032 * p.x * p.x * depth + 0.20 * depth * (1.0 - depth)),
		p.z + bend * (0.15 * p.x * depth + 0.025 * p.x * p.y + 0.24 * p.y * depth)
	) * compression;
}

void vertex() {
	source_position = VERTEX;
	float e = 0.005;
	mat3 j = mat3(
		(warp(VERTEX + vec3(e, 0, 0)) - warp(VERTEX - vec3(e, 0, 0))) / (2.0 * e),
		(warp(VERTEX + vec3(0, e, 0)) - warp(VERTEX - vec3(0, e, 0))) / (2.0 * e),
		(warp(VERTEX + vec3(0, 0, e)) - warp(VERTEX - vec3(0, 0, e))) / (2.0 * e)
	);
	NORMAL = normalize(transpose(inverse(j)) * NORMAL);
	VERTEX = warp(VERTEX);
}

void fragment() {
	ALBEDO = base_color.rgb;
	ROUGHNESS = 0.86;
	if (floor_tiles) {
		vec2 grid = source_position.xz;
		vec2 edge = abs(fract(grid + 0.5) - 0.5);
		vec2 aa = max(fwidth(grid), vec2(0.001));
		vec2 seam = 1.0 - smoothstep(vec2(0.009), vec2(0.009) + aa, edge);
		float line = max(seam.x, seam.y);
		float alternating = mod(floor(grid.x) + floor(grid.y), 2.0);
		ALBEDO = mix(base_color.rgb * (0.95 + 0.05 * alternating), vec3(0.07, 0.065, 0.055), line);
		ROUGHNESS = 0.58;
	}
}

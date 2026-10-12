shader_type spatial;
render_mode blend_add, unshaded, cull_disabled;

uniform vec3 color_a : source_color = vec3(0.45, 0.2, 0.9);
uniform vec3 color_b : source_color = vec3(0.3, 0.85, 1.0);

float hash(vec2 p) { return fract(sin(dot(p, vec2(41.3, 289.1))) * 43758.5453); }

void fragment() {
	vec2 p = UV - 0.5;
	float r = length(p);
	float a = atan(p.y, p.x);
	float swirl = sin(a * 3.0 + r * 18.0 - TIME * 2.5) * 0.5 + 0.5;
	float spark = step(0.985, hash(floor(UV * 24.0) + floor(TIME * 3.0)));
	vec3 c = mix(color_a, color_b, swirl) * (0.55 + 0.6 * (1.0 - r * 1.4));
	ALBEDO = c + vec3(spark);
	ALPHA = clamp(0.85 - r * 0.6, 0.0, 1.0);
}

shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;

uniform vec4 shallow : source_color = vec4(0.42, 0.86, 0.96, 0.82);
uniform vec4 deep : source_color = vec4(0.16, 0.5, 0.88, 0.92);
uniform vec2 flow_dir = vec2(0.0, 0.0);
uniform float flow_speed = 0.25;
uniform float tile = 1.0;
uniform float foam : hint_range(0.0, 1.0) = 0.5;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}
float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), f.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), f.x), f.y);
}

void fragment() {
	vec2 uv = UV * tile + flow_dir * TIME * flow_speed;
	float n = vnoise(uv * 5.0 + vec2(TIME * 0.06, TIME * 0.03));
	n = floor(n * 4.0) / 4.0;
	float streak = step(0.8, vnoise(uv * vec2(9.0, 2.5) + vec2(TIME * 0.12, 0.0)));
	vec3 c = mix(deep.rgb, shallow.rgb, n);
	c += streak * foam * 0.35;
	ALBEDO = c;
	ALPHA = mix(deep.a, shallow.a, n);
	ROUGHNESS = 0.12;
	SPECULAR = 0.55;
	EMISSION = c * 0.22 + vec3(streak * foam * 0.25);
}

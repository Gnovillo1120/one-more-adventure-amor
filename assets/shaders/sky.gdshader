shader_type sky;

uniform vec3 top_color : source_color = vec3(0.45, 0.55, 0.9);
uniform vec3 mid_color : source_color = vec3(0.93, 0.62, 0.74);
uniform vec3 horizon_color : source_color = vec3(1.0, 0.78, 0.55);
uniform vec3 ground_color : source_color = vec3(0.55, 0.45, 0.55);
uniform vec3 sun_color : source_color = vec3(1.0, 0.88, 0.62);
uniform vec3 sun_dir = vec3(-0.85, 0.3, -0.35);
uniform float sun_size = 0.012;
uniform float star_amount : hint_range(0.0, 1.0) = 0.0;
uniform vec3 cloud_color : source_color = vec3(1.0, 0.86, 0.86);
uniform vec3 cloud_shadow : source_color = vec3(0.78, 0.55, 0.72);
uniform float cloud_amount : hint_range(0.0, 1.0) = 0.5;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float vnoise(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), f.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), f.x), f.y);
}

void sky() {
	vec3 d = normalize(EYEDIR);
	float h = d.y;
	vec3 col;
	if (h > 0.0) {
		vec3 upper = mix(mid_color, top_color, smoothstep(0.18, 0.85, h));
		col = mix(horizon_color, upper, smoothstep(0.0, 0.32, h));
	} else {
		col = mix(horizon_color, ground_color, smoothstep(0.0, 0.3, -h));
	}
	vec3 s = normalize(sun_dir);
	float sd = dot(d, s);
	col += sun_color * smoothstep(1.0 - sun_size, 1.0 - sun_size * 0.6, sd);
	col += sun_color * pow(max(sd, 0.0), 6.0) * 0.28;
	col += sun_color * pow(max(sd, 0.0), 40.0) * 0.35;

	if (h > 0.03) {
		// Blocky pixel clouds, quantised so they read as "voxel sky".
		vec2 uv = d.xz / (h + 0.18);
		uv = uv * 1.6 + vec2(TIME * 0.006, 0.0);
		vec2 q = floor(uv * 7.0) / 7.0;
		float n = vnoise(q * 2.2) * 0.65 + vnoise(q * 5.0) * 0.35;
		float c = smoothstep(1.0 - cloud_amount * 0.55, 1.0 - cloud_amount * 0.55 + 0.04, n);
		float shade = vnoise(q * 2.2 + vec2(0.6, 0.9));
		vec3 cc = mix(cloud_shadow, cloud_color, smoothstep(0.35, 0.75, shade + h * 0.2));
		col = mix(col, cc, c * smoothstep(0.03, 0.2, h) * 0.92);
	}
	if (star_amount > 0.0 && h > 0.0) {
		vec2 sp = floor(d.xz / (h + 0.3) * 60.0);
		float st = step(0.985, hash(sp));
		col += vec3(st) * star_amount * (0.6 + 0.4 * sin(TIME * 2.0 + hash(sp) * 30.0));
	}
	COLOR = col;
}

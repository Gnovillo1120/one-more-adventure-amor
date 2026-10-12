shader_type spatial;
render_mode cull_back;

// Soft three-tone "anime" lighting used by every block, prop and character.
uniform vec4 albedo : source_color = vec4(1.0);
uniform sampler2D tex : source_color, filter_nearest_mipmap, repeat_enable;
uniform float tex_strength : hint_range(0.0, 1.0) = 0.28;
uniform float uv_scale = 1.0;
uniform sampler2D decal : source_color, filter_linear_mipmap, repeat_disable;
uniform float decal_amount : hint_range(0.0, 1.0) = 0.0;
uniform vec3 emission_color : source_color = vec3(0.0);
uniform float emission_energy = 0.0;
uniform float rim_strength = 0.0;
uniform vec3 rim_color : source_color = vec3(1.0, 0.82, 0.7);
uniform float shade_floor : hint_range(0.0, 1.0) = 0.0;

varying vec3 vcol;
varying vec3 lpos;
varying vec3 lnorm;

void vertex() {
	vcol = COLOR.rgb;
	lpos = VERTEX;
	lnorm = NORMAL;
}

void fragment() {
	vec3 an = abs(lnorm);
	vec2 tuv = (an.y > an.x && an.y > an.z) ? lpos.xz : ((an.x > an.z) ? lpos.zy : lpos.xy);
	vec3 t = texture(tex, tuv * uv_scale).rgb;
	vec3 base = albedo.rgb * vcol * mix(vec3(1.0), t, tex_strength);
	if (decal_amount > 0.0) {
		vec4 d = texture(decal, UV);
		base = mix(base, d.rgb, d.a * decal_amount);
	}
	ALBEDO = base;
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	EMISSION = emission_color * emission_energy + rim_color * rim * rim_strength * base;
}

void light() {
	float k = dot(NORMAL, LIGHT) * ATTENUATION;
	float lit = 0.5 * smoothstep(-0.02, 0.06, k) + 0.5 * smoothstep(0.34, 0.42, k);
	lit = max(lit, shade_floor);
	DIFFUSE_LIGHT += LIGHT_COLOR * lit / PI;
}

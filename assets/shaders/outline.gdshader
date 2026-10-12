shader_type spatial;
render_mode cull_front, unshaded;

// Inverted-hull ink outline. Works on box-built characters because it pushes
// every vertex outward from the mesh centre instead of along (hard) normals.
uniform vec4 outline_color : source_color = vec4(0.16, 0.09, 0.14, 1.0);
uniform float width = 0.03;

void vertex() {
	VERTEX += sign(VERTEX) * width;
}

void fragment() {
	ALBEDO = outline_color.rgb;
}

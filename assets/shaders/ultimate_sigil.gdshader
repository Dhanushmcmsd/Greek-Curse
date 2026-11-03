shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled;
uniform vec4 tint : source_color = vec4(0.4, 0.7, 1.0, 1.0);
uniform float age = 0.0;
uniform float sides = 6.0;
uniform float intensity = 1.0;
void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float r = length(p);
	float a = atan(p.y, p.x);
	float ring = exp(-abs(r - 0.75) * 115.0) + 0.5 * exp(-abs(r - 0.90) * 100.0);
	float teeth = pow(max(0.0, cos(a * sides)), 20.0) * exp(-abs(r - 0.82) * 35.0);
	float inner = exp(-abs(r - (0.49 + 0.04 * cos(a * sides))) * 90.0);
	ALBEDO = tint.rgb;
	ALPHA = (ring + teeth + inner * 0.65) * (1.0 - smoothstep(0.3, 1.0, age)) * intensity;
}

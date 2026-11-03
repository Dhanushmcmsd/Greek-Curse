shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled;
uniform vec4 tint : source_color = vec4(0.4, 0.7, 1.0, 1.0);
uniform float age = 0.0;
uniform float intensity = 1.0;
void fragment() {
	float edge = abs(UV.x * 2.0 - 1.0);
	float halo = pow(max(0.0, 1.0 - edge), 3.0);
	float core = 1.0 - smoothstep(0.03, 0.16, edge);
	float taper = 1.0 - smoothstep(0.05, 0.78, age);
	float filaments = 0.85 + 0.15 * sin(UV.y * 95.0 + age * 21.0);
	ALBEDO = mix(tint.rgb, vec3(1.0), core * 0.95);
	ALPHA = (halo * 0.65 + core) * taper * filaments * intensity;
}

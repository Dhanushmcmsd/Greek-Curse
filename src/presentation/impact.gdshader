shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never;

uniform vec4 tint : source_color = vec4(1.0, 0.65, 0.22, 1.0);
uniform vec4 rim_color : source_color = vec4(1.0, 0.95, 0.8, 1.0);
uniform float strength = 1.0;
uniform bool guard = false;
uniform float shock_phase = 0.0;

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float r = length(p);
	float angle = atan(p.y, p.x);
	
	// Crisp shockwave expansion ring
	float ring = exp(-pow((r - 0.62) * 24.0, 2.0));
	float outer_ring = exp(-pow((r - 0.88) * 32.0, 2.0)) * 0.5;
	
	// Multi-frequency directional impact sparks / slash rays (Tekken / Fahkumram style)
	float primary_rays = pow(abs(cos(angle * 6.0)), 28.0) * pow(max(0.0, 1.0 - r), 1.2);
	float secondary_rays = pow(abs(sin(angle * 12.0 + 0.3)), 36.0) * pow(max(0.0, 0.9 - r), 1.6) * 0.7;
	float rays = primary_rays + secondary_rays;
	
	// Blazing high-energy central impact core with hot white center
	float core = exp(-r * r * 45.0);
	float hot_center = exp(-r * r * 160.0);
	
	float a = 0.0;
	vec3 out_color = tint.rgb;
	
	if (guard) {
		// Hexagonal crystal guard ripple
		float hex_ripple = pow(abs(cos(angle * 3.0)), 8.0) * 0.3;
		a = ring * 0.85 + core * 0.35 + hex_ripple * ring;
		out_color = mix(tint.rgb, vec3(0.7, 0.9, 1.0), core * 0.6);
	} else {
		// Massive impact frame burst
		a = core * 1.2 + rays * 1.5 + ring * 0.65 + outer_ring;
		out_color = mix(tint.rgb, rim_color.rgb, hot_center * 0.9 + rays * 0.3);
	}
	
	float vignette = smoothstep(1.0, 0.75, r);
	ALBEDO = out_color * (1.0 + hot_center * 1.5);
	ALPHA = clamp(a * strength * vignette, 0.0, 1.0);
}


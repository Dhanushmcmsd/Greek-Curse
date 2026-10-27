shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never;

uniform vec4 tint : source_color = vec4(1.0, 0.65, 0.22, 1.0);
uniform vec4 rim_color : source_color = vec4(1.0, 0.95, 0.8, 1.0);
uniform float strength = 1.0;
uniform bool guard = false;
uniform float shock_phase = 0.0;
uniform int combo_tier = 0;  // 0-3 escalating combo visual tier

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float r = length(p);
	float angle = atan(p.y, p.x);
	
	// Crisp shockwave expansion ring — double ring for heavier impact
	float ring = exp(-pow((r - 0.58) * 26.0, 2.0));
	float outer_ring = exp(-pow((r - 0.82) * 36.0, 2.0)) * 0.55;
	float tertiary_ring = exp(-pow((r - 0.95) * 48.0, 2.0)) * 0.28;
	
	// Multi-frequency directional impact sparks / slash rays (Tekken-8 Fahkumram style)
	float primary_rays = pow(abs(cos(angle * 6.0 + shock_phase)), 24.0) * pow(max(0.0, 1.0 - r), 1.1);
	float secondary_rays = pow(abs(sin(angle * 11.0 + 0.4 + shock_phase * 0.7)), 32.0) * pow(max(0.0, 0.92 - r), 1.5) * 0.75;
	float diagonal_rays = pow(abs(cos(angle * 4.0 - 0.8 + shock_phase * 0.3)), 38.0) * pow(max(0.0, 0.8 - r), 2.0) * 0.55;
	float rays = primary_rays + secondary_rays + diagonal_rays;
	
	// High-energy blazing central core with hot-white center
	float core = exp(-r * r * 42.0);
	float hot_center = exp(-r * r * 180.0);
	float mid_glow = exp(-r * r * 18.0) * 0.4;
	
	// Combo tier: add crackling energy aura at higher tiers
	float tier_glow = 0.0;
	if (combo_tier >= 1) {
		float crackle = pow(abs(sin(angle * 9.0 + shock_phase * 2.0)), 20.0) * exp(-r * r * 8.0) * 0.5;
		tier_glow += crackle * float(combo_tier) * 0.35;
	}
	
	float a = 0.0;
	vec3 out_color = tint.rgb;
	
	if (guard) {
		// Hexagonal crystal guard ripple — MK block effect
		float hex_a = cos(angle * 3.0);
		float hex_b = cos(angle * 3.0 + 2.094);
		float hex_c = cos(angle * 3.0 + 4.188);
		float hex_ripple = (pow(abs(hex_a), 5.0) + pow(abs(hex_b), 5.0) + pow(abs(hex_c), 5.0)) * 0.18;
		a = ring * 0.9 + outer_ring * 0.4 + core * 0.4 + hex_ripple * ring * 0.8;
		out_color = mix(tint.rgb, vec3(0.65, 0.88, 1.0), core * 0.7 + hex_ripple * 0.4);
	} else {
		// Massive Tekken-style impact burst with combo tier escalation
		a = core * 1.3 + rays * 1.65 + ring * 0.72 + outer_ring * 0.45 + tertiary_ring * 0.22 + tier_glow;
		
		// Combo tier color shifts: yellow → orange → purple → cyan
		vec3 tier_tint = tint.rgb;
		if (combo_tier == 1) tier_tint = mix(tint.rgb, vec3(1.0, 0.45, 0.1), 0.4);
		if (combo_tier == 2) tier_tint = mix(tint.rgb, vec3(0.85, 0.2, 0.9), 0.55);
		if (combo_tier >= 3) tier_tint = mix(tint.rgb, vec3(0.2, 0.9, 1.0), 0.65);
		
		out_color = mix(tier_tint, rim_color.rgb, hot_center * 0.92 + rays * 0.28);
	}
	
	// Radial vignette for clean edge falloff
	float vignette = smoothstep(1.05, 0.7, r);
	ALBEDO = out_color * (1.0 + hot_center * 1.8 + mid_glow);
	ALPHA = clamp(a * strength * vignette, 0.0, 1.0);
}

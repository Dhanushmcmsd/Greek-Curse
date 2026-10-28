shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never;
uniform vec4 tint : source_color = vec4(1.0, 0.65, 0.22, 1.0);
uniform float strength = 1.0;
uniform bool guard = false;
uniform int combo_tier = 0;
void fragment() {
    vec2 p = UV * 2.0 - 1.0;
    float r = length(p);
    float a = atan(p.y, p.x);
    float core = exp(-dot(p, p) * 100.0);
    float bloom = exp(-dot(p, p) * 14.0) * 0.2;
    float rays = pow(max(0.0, cos(a * 7.0 + sin(a * 3.0) * 1.4)), 55.0);
    rays *= pow(max(0.0, 1.0 - r), 1.5) * smoothstep(0.02, 0.14, r);
    float sliver = exp(-pow(p.y * 36.0 + sin(p.x * 12.0) * 0.5, 2.0));
    sliver *= pow(max(0.0, 1.0 - abs(p.x)), 3.0) * 0.35;
    float guard_arc = exp(-pow((r - 0.55) * 45.0, 2.0)) * max(0.0, cos(a + 0.4));
    float mask = core + bloom + rays + sliver;
    if (guard) { mask = guard_arc * 0.7 + core * 0.4 + rays * 0.25; }
    ALBEDO = mix(tint.rgb, vec3(1.0, 0.96, 0.84), core) * (1.0 + core);
    ALPHA = mask * strength * (1.0 - smoothstep(0.7, 1.0, r));
}

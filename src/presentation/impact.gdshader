shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never;
uniform vec4 tint : source_color = vec4(1.0,0.6,0.2,1.0);
uniform float strength = 1.0;
uniform bool guard = false;
void fragment() {
 vec2 p = UV * 2.0 - 1.0;
 float r = length(p);
 float ring = exp(-pow((r - 0.66) * 26.0, 2.0));
 float rays = pow(abs(cos(atan(p.y,p.x)*7.0)), 22.0) * pow(max(0.0,1.0-r), 1.4);
 float core = exp(-r*r*60.0);
 float a = guard ? ring * 0.7 + core * 0.2 : core + rays + ring * 0.25;
 ALBEDO = tint.rgb;
 ALPHA = a * strength * smoothstep(1.0,0.85,r);
}

shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never;
uniform sampler2D artwork : filter_linear_mipmap;
uniform vec4 tint : source_color = vec4(1.0);
uniform float age = 0.0;
uniform float opacity = 1.0;
uniform int layer = 0;
void fragment() {
 vec2 p = UV * 2.0 - 1.0;
 float r = length(p);
 vec4 tex = texture(artwork, UV);
 float mask = max(tex.r, max(tex.g, tex.b));
 if (layer == 1) { mask = tex.g * exp(-pow((r - 0.74) * 28.0, 2.0)) * (0.45 + 0.55 * max(0.0, sin(atan(p.y,p.x)*5.0))); }
 if (layer == 2) { mask = tex.r; }
 float edge = 1.0 - smoothstep(0.85, 1.0, r);
 ALBEDO = mix(tint.rgb, vec3(1.0,0.96,0.85), pow(max(0.0,1.0-r),8.0));
 ALPHA = mask * edge * opacity * pow(1.0-age, 1.5);
}

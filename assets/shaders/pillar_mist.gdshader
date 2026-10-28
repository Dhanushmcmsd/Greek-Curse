shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled, depth_draw_never;
uniform sampler2D smoke_atlas : filter_linear_mipmap;
uniform float phase = 0.0;
void vertex() {
 VERTEX.x += sin(TIME * 0.24 + phase * 6.28) * 0.22;
 VERTEX.y += sin(TIME * 0.19 + phase * 6.28) * 0.06;
}
void fragment() {
 float life = fract(TIME * 0.055 + phase);
 float frame = floor(24.0 + life * 38.0);
 vec2 cell = vec2(mod(frame, 9.0), floor(frame / 9.0));
 vec3 smoke = texture(smoke_atlas, (cell + mix(vec2(0.015), vec2(0.985), UV)) / vec2(9.0, 7.0)).rgb;
 float density = max(smoke.r, max(smoke.g, smoke.b));
 float fade = smoothstep(0.0, 0.18, life) * (1.0 - smoothstep(0.75, 1.0, life));
 ALBEDO = vec3(0.36, 0.44, 0.52);
 ALPHA = density * fade * 0.62;
}

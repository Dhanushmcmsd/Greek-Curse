shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled, depth_draw_never;
uniform float opacity = 0.24;
uniform float age = 0.0;
uniform vec2 grid = vec2(9.0, 7.0);
uniform sampler2D smoke_atlas : filter_linear_mipmap;
void fragment() {
 float frame = floor(clamp(age, 0.0, 0.999) * grid.x * grid.y);
 vec2 cell = vec2(mod(frame, grid.x), floor(frame / grid.x));
 vec2 sample_uv = (cell + mix(vec2(0.015), vec2(0.985), UV)) / grid;
 vec4 smoke = texture(smoke_atlas, sample_uv);
 float density = max(smoke.r, max(smoke.g, smoke.b));
 ALBEDO = mix(vec3(0.24,0.29,0.34), vec3(0.62,0.65,0.67), smoke.g);
 ALPHA = density * opacity;
}

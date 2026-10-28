shader_type spatial;
render_mode blend_mix, cull_disabled;
uniform sampler2D stone : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D stone_normal : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
varying vec3 world_position;
void vertex() { world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
    vec2 p = world_position.xz;
    vec3 grain = texture(stone, p * 0.20).rgb;
    ALBEDO = grain * vec3(0.64, 0.68, 0.72);
    NORMAL_MAP = texture(stone_normal, p * 0.42).rgb;
    NORMAL_MAP_DEPTH = 0.55;
    ROUGHNESS = 0.86;
    // A long irregular feather replaces the hard foreground/background edge.
    float breakup = texture(stone, p * 0.27).r * 0.7;
    ALPHA = smoothstep(-9.0, -5.5, p.y + breakup);
}

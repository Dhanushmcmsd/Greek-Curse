shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
uniform vec4 stone_color : source_color = vec4(0.19, 0.24, 0.29, 1.0);
varying vec3 world_pos;
void vertex() {
    world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}
void fragment() {
    vec2 p = world_pos.xz;
    float warp = sin(p.x * 2.7 + sin(p.y * 3.1)) * 0.8;
    float vein = pow(abs(sin(p.x * 4.2 + p.y * 1.7 + warp)), 18.0);
    float grain = sin(p.x * 91.0) * sin(p.y * 87.0) * 0.018;
    ALBEDO = stone_color.rgb * (0.88 + grain) + vec3(0.08, 0.085, 0.09) * vein;
    ROUGHNESS = 0.62 + vein * 0.12;
    METALLIC = 0.08;
}

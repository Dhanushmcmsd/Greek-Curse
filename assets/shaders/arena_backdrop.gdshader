shader_type spatial;
render_mode unshaded, fog_disabled, cull_disabled;
uniform sampler2D backdrop : source_color, filter_linear_mipmap;
void fragment() {
    ALBEDO = texture(backdrop, UV).rgb;
}

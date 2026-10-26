shader_type spatial;
render_mode cull_disabled, depth_prepass_alpha;
uniform vec3 joint;
uniform vec3 axis;
uniform float reach = 0.18;
uniform vec4 base_color : source_color = vec4(1.0);
uniform sampler2D skin_texture : source_color;
uniform bool textured = false;
varying float along;
void vertex() { along = COLOR.r; }
void fragment() {
 if (along >= 1.0) { discard; }
 vec4 skin = base_color * (textured ? texture(skin_texture, UV) : vec4(1.0));
 float blend = smoothstep(0.15,0.9,along);
 ALBEDO = mix(skin.rgb,vec3(0.055,0.035,0.025),blend);
 ROUGHNESS = 0.6;
 ALPHA = skin.a*(1.0-smoothstep(0.7,1.0,along));
}

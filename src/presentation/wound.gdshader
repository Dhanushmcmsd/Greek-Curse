shader_type spatial;
render_mode cull_disabled;
uniform vec4 flesh : source_color = vec4(0.28,0.025,0.035,1.0);
void fragment() {
 float fibers = 0.5+0.5*sin(UV.x*115.0 + sin(UV.y*70.0)*3.0);
 float mottling = 0.5+0.5*sin(UV.x*53.0)*cos(UV.y*41.0);
 ALBEDO = flesh.rgb * (0.5+fibers*0.25+mottling*0.3);
 ROUGHNESS = 0.3;
}

shader_type spatial;
render_mode cull_disabled, depth_draw_never;
uniform vec4 blood : source_color = vec4(0.4,0.01,0.02,1.0);
uniform float fade = 1.0;
void fragment() {
 vec2 p = UV*2.0-1.0;
 float angle = atan(p.y,p.x);
 float edge = 0.72 + 0.09*sin(angle*7.0) + 0.06*cos(angle*11.0);
 float a = 1.0-smoothstep(edge-0.1,edge,length(p));
 ALBEDO = blood.rgb * mix(0.4,1.0,length(p));
 ROUGHNESS = 0.25;
 ALPHA = a * fade * 0.8;
}

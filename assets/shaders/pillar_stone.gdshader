shader_type spatial;
uniform sampler2D backdrop : source_color, filter_linear_mipmap, repeat_enable;
varying vec3 local_position;
uniform bool fluted = false;
void vertex() {
 if (fluted && abs(VERTEX.y) < 1.224) {
  float a = atan(VERTEX.z, VERTEX.x);
  VERTEX.xz *= 1.0 - 0.065 * (0.5 + 0.5 * cos(a * 20.0));
 }
 local_position = VERTEX;
}
void fragment() {
 vec3 weights = pow(abs(NORMAL), vec3(4.0));
 weights /= max(weights.x + weights.y + weights.z, 0.001);
 vec3 stone = texture(backdrop, local_position.yz * 1.5).rgb * weights.x;
 stone += texture(backdrop, local_position.xz * 1.5).rgb * weights.y;
 stone += texture(backdrop, local_position.xy * 1.5).rgb * weights.z;
 ALBEDO = stone * vec3(0.72,0.76,0.81);
 ROUGHNESS = 0.92;
 SPECULAR = 0.12;
}

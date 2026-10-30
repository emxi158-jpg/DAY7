shader_type spatial;
render_mode unshaded,cull_back;
uniform sampler2D reflection_texture:filter_linear;
void fragment(){
 vec2 q=vec2(1.-UV.x,UV.y);
 vec3 reflected=texture(reflection_texture,q).rgb;
 float border=min(min(UV.x,1.-UV.x),min(UV.y,1.-UV.y));
 float tarnish=(1.-smoothstep(.004,.023,border))*.27;
 ALBEDO=mix(reflected*vec3(.92,.94,.93),vec3(.025,.023,.018),tarnish);
}

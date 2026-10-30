shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;
uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform float water_level=1.395;
uniform float absorption_strength=1.0;
varying vec3 bottle_position;
void vertex(){bottle_position=VERTEX;}
float h(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
void fragment(){
 float nv=max(abs(dot(normalize(NORMAL),normalize(VIEW))),.12);
 float fresnel=.043+(1.0-.043)*pow(1.0-nv,5.0);
 float wet=1.0-smoothstep(water_level-.002,water_level+.002,bottle_position.y);
 float wall_path=.0035/nv;
 float water_path=.255*nv*wet;
 vec3 absorb=vec3(310.0,175.0,4.0)*wall_path+vec3(3.6,1.8,.08)*water_path;
 vec3 transmission=exp(-absorb*absorption_strength);
 // Small lens displacement, stronger through the water than the air pocket.
 vec2 lens=NORMAL.xy*(.0018+.0045*wet)*(1.0-nv*.35);
 vec3 behind=textureLod(screen_texture,clamp(SCREEN_UV-lens,vec2(.001),vec2(.999)),.25).rgb;
 float grip=exp(-pow((bottle_position.y-1.219)/.024,2.0))+exp(-pow((bottle_position.y-1.284)/.024,2.0))+exp(-pow((bottle_position.y-1.455)/.028,2.0));
 float scuff=pow(h(floor(UV*vec2(1400.0,650.0))),16.0)*clamp(grip,0.0,1.0);
 ALBEDO=vec3(.022,.075,.28);
 METALLIC=0.0;SPECULAR=.56;
 ROUGHNESS=clamp(.105+.045*grip+.13*scuff,.10,.27);
 CLEARCOAT=.22;CLEARCOAT_ROUGHNESS=.18;
 // This is transmitted scene radiance, not light emitted into the room.
 EMISSION=behind*transmission*(1.0-fresnel);
 ALPHA=1.0;
}




shader_type spatial;

uniform vec4 paint_color:source_color=vec4(.32,.38,.345,1.);
uniform sampler2D micro_normal:hint_normal,filter_linear_mipmap_anisotropic,repeat_enable;
uniform sampler2D coating_rough:filter_linear_mipmap_anisotropic,repeat_enable;
uniform bool door_panel=false;
varying vec3 position_local;
varying vec3 normal_local;
float hash3(vec3 p){return fract(sin(dot(p,vec3(127.1,311.7,74.7)))*43758.5453);}
float noise3(vec3 p){vec3 i=floor(p),f=fract(p);f=f*f*(3.-2.*f);return mix(mix(mix(hash3(i),hash3(i+vec3(1,0,0)),f.x),mix(hash3(i+vec3(0,1,0)),hash3(i+vec3(1,1,0)),f.x),f.y),mix(mix(hash3(i+vec3(0,0,1)),hash3(i+vec3(1,0,1)),f.x),mix(hash3(i+vec3(0,1,1)),hash3(i+vec3(1,1,1)),f.x),f.y),f.z);}
void vertex(){position_local=VERTEX;normal_local=NORMAL;}
void fragment(){
 vec3 p=position_local;
 float coating=noise3(p*12.0),grain=noise3(p*310.0);
 float edge=0.,handling=0.;
 if(door_panel){
  float distance_edge=min(min(abs(p.x-.006),abs(p.x-1.182)),min(abs(p.y-.006),abs(p.y-2.300)));
  edge=(1.-smoothstep(.002,.014,distance_edge))*smoothstep(.63,.80,noise3(p*110.0));
  handling=exp(-pow((p.x-.974)/.10,2.)-pow((p.y-1.168)/.18,2.));
 }
 vec3 enamel=paint_color.rgb*(.91+.15*coating);
 vec3 steel=vec3(.34,.36,.34);
 ALBEDO=mix(enamel,steel,edge*.85);
 ROUGHNESS=mix(.30+.23*coating+.03*grain-.08*handling,.32,edge);
 if(abs(normal_local.x)>.85){ROUGHNESS=max(ROUGHNESS,.66);}
 METALLIC=mix(.12,.84,edge);
 SPECULAR=.50;
 CLEARCOAT=0.;CLEARCOAT_ROUGHNESS=.45;
 vec3 an=abs(normal_local);
 vec2 surface_uv=an.z>an.x && an.z>an.y ? p.xy : (an.x>an.y ? p.zy : p.xz);
 // Godot imports normal maps as two-channel RGTC; B is zero, not a signed Z normal.
 vec2 detail_xy=(texture(micro_normal,surface_uv*.75).rg*2.-1.)*.38;
 vec3 sampled=vec3(detail_xy,sqrt(max(1.-dot(detail_xy,detail_xy),.0001)));
 ROUGHNESS=clamp(.19+.64*texture(coating_rough,surface_uv*.75).r-.07*handling,.25,.73);
 vec3 dp1=dFdx(VERTEX),dp2=dFdy(VERTEX);
 vec2 du1=dFdx(surface_uv),du2=dFdy(surface_uv);
 vec3 dp2perp=cross(dp2,NORMAL),dp1perp=cross(NORMAL,dp1);
 vec3 T=dp2perp*du1.x+dp1perp*du2.x;
 vec3 B=dp2perp*du1.y+dp1perp*du2.y;
 float invmax=inversesqrt(max(max(dot(T,T),dot(B,B)),.00000001));
 NORMAL=normalize(mat3(T*invmax,B*invmax,NORMAL)*sampled);
}

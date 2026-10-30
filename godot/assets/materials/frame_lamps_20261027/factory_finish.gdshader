shader_type spatial;
render_mode cull_disabled;
uniform vec4 finish_color:source_color=vec4(.28,.31,.28,1.);
uniform float rough_base=.28;
uniform float metalness=.06;
uniform float wear_amount=.45;
uniform vec3 half_size=vec3(.041,1.205,.08);
uniform sampler2D detail_normal:hint_normal,filter_linear_mipmap_anisotropic,repeat_enable;
uniform sampler2D detail_rough:filter_linear_mipmap_anisotropic,repeat_enable;
varying vec3 p;
varying vec3 n;
float h(vec3 q){return fract(sin(dot(q,vec3(127.1,311.7,74.7)))*43758.5453);}
void vertex(){p=VERTEX;n=NORMAL;}
void fragment(){
 vec3 an=abs(n);vec2 uv=an.z>an.x && an.z>an.y?p.xy:(an.x>an.y?p.zy:p.xz);
 float r=texture(detail_rough,uv*3.0).r;
 vec3 dist=max(half_size-abs(p),vec3(0.));
 float second=min(min(max(dist.x,dist.y),max(dist.y,dist.z)),max(dist.x,dist.z));
 float edge=(1.-smoothstep(.0005,.0032,second))*smoothstep(.78,.94,h(floor(p*680.)))*wear_amount;
 ALBEDO=mix(finish_color.rgb*(.985+.025*r),vec3(.25,.27,.265),edge);
 METALLIC=mix(metalness,.80,edge);ROUGHNESS=clamp(rough_base+.10*(r-.5)+edge*.05,.16,.58);SPECULAR=.52;
 CLEARCOAT=.12;CLEARCOAT_ROUGHNESS=.27;
 vec2 xy=(texture(detail_normal,uv*3.).rg*2.-1.)*.07;
 vec3 sn=vec3(xy,sqrt(max(1.-dot(xy,xy),.0001)));
 vec3 dp1=dFdx(VERTEX),dp2=dFdy(VERTEX);vec2 du1=dFdx(uv),du2=dFdy(uv);
 vec3 dp2perp=cross(dp2,NORMAL),dp1perp=cross(NORMAL,dp1);
 vec3 T=dp2perp*du1.x+dp1perp*du2.x,B=dp2perp*du1.y+dp1perp*du2.y;
 float invmax=inversesqrt(max(max(dot(T,T),dot(B,B)),.00000001));NORMAL=normalize(mat3(T*invmax,B*invmax,NORMAL)*sn);
}

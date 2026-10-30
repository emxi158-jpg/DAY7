shader_type spatial;
render_mode cull_disabled;
uniform vec4 metal_tint:source_color=vec4(.65,.67,.65,1.);
uniform float metalness=.94;
uniform float rough_base=.30;
uniform float rough_span=.20;
uniform float detail_strength=.12;
uniform float texture_meters=.55;
uniform sampler2D detail_normal:hint_normal,filter_linear_mipmap_anisotropic,repeat_enable;
uniform sampler2D detail_rough:filter_linear_mipmap_anisotropic,repeat_enable;
uniform vec3 metric_scale=vec3(1.);
varying vec3 model_pos;
varying vec3 model_normal;
void vertex(){model_pos=VERTEX;model_normal=NORMAL;}
void fragment(){
 vec3 p=model_pos*metric_scale;vec3 an=abs(model_normal);
 vec2 uv=an.z>an.x && an.z>an.y ? p.xy : (an.x>an.y ? p.zy : p.xz);
 uv/=texture_meters;
 float r=texture(detail_rough,uv).r;
 ALBEDO=metal_tint.rgb*(.97+.05*r);
 METALLIC=clamp(metalness+.10*(.5-r),0.,1.);ROUGHNESS=clamp(rough_base+rough_span*(r-.5),.08,.82);SPECULAR=.5;
 vec2 xy=(texture(detail_normal,uv).rg*2.-1.)*detail_strength;
 vec3 sampled=vec3(xy,sqrt(max(1.-dot(xy,xy),.0001)));
 vec3 dp1=dFdx(VERTEX),dp2=dFdy(VERTEX);vec2 du1=dFdx(uv),du2=dFdy(uv);
 vec3 dp2perp=cross(dp2,NORMAL),dp1perp=cross(NORMAL,dp1);
 vec3 T=dp2perp*du1.x+dp1perp*du2.x,B=dp2perp*du1.y+dp1perp*du2.y;
 float invmax=inversesqrt(max(max(dot(T,T),dot(B,B)),.00000001));
 NORMAL=normalize(mat3(T*invmax,B*invmax,NORMAL)*sampled);
}

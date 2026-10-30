shader_type spatial;
uniform sampler2D print_map:source_color,filter_linear_mipmap_anisotropic;
uniform sampler2D stock_age:source_color,filter_linear_mipmap_anisotropic;
uniform sampler2D stock_normal:hint_normal,filter_linear_mipmap_anisotropic;
uniform sampler2D stock_rough:filter_linear_mipmap_anisotropic;
uniform vec4 paper_tint:source_color=vec4(1.);
uniform bool printed=true;
void fragment(){
 vec3 ink=printed?texture(print_map,UV).rgb:vec3(.76,.74,.67);
 ALBEDO=ink*texture(stock_age,UV).rgb*paper_tint.rgb;
 ROUGHNESS=texture(stock_rough,UV).r;
 NORMAL_MAP=texture(stock_normal,UV).rgb;NORMAL_MAP_DEPTH=.32;
 METALLIC=0.;SPECULAR=.18;
}

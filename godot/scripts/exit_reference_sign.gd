extends RefCounted
const G=preload("res://tools/surface_geometry.gd")
static func spill_texture()->ImageTexture:
 var image=Image.create(128,128,false,Image.FORMAT_RGBA8)
 var separation=.17
 for y in range(128):
  for x in range(128):
   var p=Vector2((x/127.0-.5)*1.05,(y/127.0-.5)*.75);var energy=0.0
   for sy in [-1.,0.,1.]:
    for sx in [-1.,0.,1.]:
     var r2=p.distance_squared_to(Vector2(sx*.11,sy*.04))+separation*separation
     energy+=separation*separation/(r2*r2)
   var w=clampf(energy/205.,0.,1.)
   var edge=pow(clampf(1.-absf(p.x)/.525,0.,1.),.18)*pow(clampf(1.-absf(p.y)/.375,0.,1.),.18)
   var linear=Color(.002*w*edge,.052*w*edge,.037*w*edge,1.)
   image.set_pixel(x,y,linear.linear_to_srgb())
 return ImageTexture.create_from_image(image)
static func apply(world):
 var model=world.actors.exit.model;var face=model.find_child("ExitSign_Face",true,false);var housing=model.find_child("ExitSign_Housing",true,false);var text_=model.find_child("ExitSign_Text",true,false)
 housing.mesh=G.rounded_box(Vector3(.62,.145,.065),.006)
 var hm=housing.get_active_material(0).duplicate()
 if hm is ShaderMaterial:hm.set_shader_parameter("metal_tint",Color(.09,.105,.10));hm.set_shader_parameter("rough_base",.30);hm.set_shader_parameter("detail_strength",.035)
 housing.material_override=hm
 housing.layers=1<<14 # Keep the dark end caps out of the surface-spill projection.
 face.mesh=G.rounded_box(Vector3(.30,.112,.004),.002)
 face.position.z=.035
 var fs=Shader.new();fs.code="shader_type spatial;render_mode unshaded;varying vec2 p;void vertex(){p=VERTEX.xy;}void fragment(){float center=exp(-dot(p*vec2(7.0,12.0),p*vec2(7.0,12.0)));ALBEDO=vec3(.010,.215,.155)*(1.0+.10*center);}"
 var fm=ShaderMaterial.new();fm.shader=fs;fm.resource_name="EXIT_MutedTealDiffuser";face.material_override=fm
 var font=load("res://assets/fonts/BarlowCondensed-Regular.res")
 var textmesh=TextMesh.new();textmesh.text="EXIT";textmesh.font=font;textmesh.font_size=64;textmesh.pixel_size=.00180;textmesh.depth=.0003
 text_.mesh=textmesh;text_.scale=Vector3(1.12,1.,1.)
 var ts=Shader.new();ts.code="shader_type spatial;render_mode unshaded;void fragment(){ALBEDO=vec3(1.6,2.25,1.95);}"
 var tm=ShaderMaterial.new();tm.shader=ts;tm.resource_name="EXIT_SlimWarmWhiteLetters";text_.material_override=tm
 var inward=world.actors.exit.global_basis.z.normalized();var fc=(face.global_transform*face.mesh.get_aabb()).get_center()
 text_.global_position=fc+inward*.005
 var group=model.find_child("ExitSignLighting",true,false)
 var spill=Decal.new();spill.name="EXIT_NearSurfaceSpill";group.add_child(spill)
 spill.size=Vector3(1.05,.26,.75);spill.texture_emission=spill_texture();spill.emission_energy=.52;spill.albedo_mix=0.;spill.modulate=Color.WHITE;spill.normal_fade=.82;spill.upper_fade=.15;spill.lower_fade=.15;spill.cull_mask=1|(1<<18)
 spill.global_transform=Transform3D(Basis(Vector3(0,0,1),Vector3(-1,0,0),Vector3(0,-1,0)),Vector3(3.81,2.64,1.2))
 world.set_meta("exit_reference_sign",true)



extends RefCounted
# Exactly three practical sources: clock lamp, warm entrance glass, cool exit glass.
static func apply(world:Node3D)->void:
 var model=world.actors.exit.model
 var glass=model.find_child("ExitDoor_Glass",true,false)
 var leaf=model.find_child("ExitDoor_Leaf",true,false)
 var glass_center=(glass.global_transform*glass.mesh.get_aabb()).get_center()
 var inward=world.actors.exit.global_basis.z.normalized()
 var glass_shader=Shader.new()
 glass_shader.code="""
shader_type spatial;
render_mode cull_disabled,unshaded;
varying vec3 pane_position;
void vertex(){pane_position=VERTEX;}
float h(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 p){vec2 i=floor(p);vec2 f=fract(p);f=f*f*(3.0-2.0*f);return mix(mix(h(i),h(i+vec2(1,0)),f.x),mix(h(i+vec2(0,1)),h(i+vec2(1,1)),f.x),f.y);}
void fragment(){
 float frost=noise(pane_position.xy*210.0)*.65+noise(pane_position.xy*38.0)*.35;
 ALBEDO=vec3(.38,.50,.62)*(.95+.10*frost);
 ROUGHNESS=.32;
 METALLIC=0.0;
 EMISSION=vec3(.12,.16,.20);
}
"""
 var glass_mat=ShaderMaterial.new()
 glass_mat.shader=glass_shader
 glass.material_override=glass_mat
 var sign=model.find_child("ExitSign_Assembly",true,false)
 var face=model.find_child("ExitSign_Face",true,false)
 var housing=model.find_child("ExitSign_Housing",true,false)
 var text=model.find_child("ExitSign_Text",true,false)
 var face_center=(face.global_transform*face.mesh.get_aabb()).get_center()
 var face_mat=StandardMaterial3D.new()
 face_mat.albedo_color=Color(.025,.14,.095)
 face_mat.roughness=.5
 face_mat.emission_enabled=true
 face_mat.emission=Color(.07,.58,.37)
 face_mat.emission_energy_multiplier=1.35
 face.material_override=face_mat
 var text_mesh=TextMesh.new()
 text_mesh.text="EXIT"
 text_mesh.font=load("res://assets/fonts/BarlowCondensed-Bold.ttf")
 text_mesh.font_size=64
 text_mesh.pixel_size=.0025
 text_mesh.depth=.0006
 text.mesh=text_mesh
 var text_shader=Shader.new()
 text_shader.code="shader_type spatial;render_mode unshaded;void fragment(){ALBEDO=vec3(3.2,4.5,3.9);}"
 var text_mat=ShaderMaterial.new()
 text_mat.shader=text_shader
 text_mat.resource_name="ExitSign_HDR_LuminousLettering"
 text.material_override=text_mat
 text.global_transform=Transform3D(Basis.looking_at(-inward,Vector3.UP),face_center+inward*.008)
 housing.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_ON
 var cold_group=Node3D.new();cold_group.name="ColdWindowLighting";leaf.add_child(cold_group)
 var source=world.get_node("RoomDecor/Lighting/ExitWindow_CoolTransmission")
 source.reparent(cold_group,true)
 var sign_group=Node3D.new();sign_group.name="ExitSignLighting";sign.add_child(sign_group)
 face.gi_mode=GeometryInstance3D.GI_MODE_DISABLED
 # Keep HDR lettering above the existing glow threshold; do not raise global bloom.
 world.set_meta("exit_light_groups",{"cold":cold_group,"sign":sign_group})
 load("res://scripts/exit_reference_sign.gd").apply(world)
 print("THREE_PRACTICAL_SOURCES_READY: ClockSconce_Warm, EntranceWindow_WarmTransmission, ExitWindow_CoolTransmission; no fill lights")
static func set_surface_lighting(world:Node,cold_enabled:bool,sign_enabled:bool)->void:
 var groups=world.get_meta("exit_light_groups");groups.cold.visible=cold_enabled;groups.sign.visible=sign_enabled




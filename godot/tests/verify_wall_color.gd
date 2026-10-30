extends SceneTree
func _initialize():call_deferred("run")
func run():
 var old=load("D:/yingyong/chatgpt/DAY7/_local_backup/wall_color_20261021_before/room_decor.scn").instantiate()
 var now=load("res://room_decor.scn").instantiate()
 var checked=0;var changed=0
 for a in old.find_children("*","MeshInstance3D",true,false):
  var b=now.get_node(old.get_path_to(a))
  assert(a.transform==b.transform and a.visible==b.visible,"Geometry changed "+str(a.name))
  for i in range(a.mesh.get_surface_count()):
   var ma=a.get_active_material(i);var mb=b.get_active_material(i)
   if not ma is BaseMaterial3D:continue
   for p in ["albedo_texture","normal_texture","normal_scale","roughness","roughness_texture","metallic","metallic_specular","uv1_scale"]:assert(ma.get(p)==mb.get(p),"Texture or response changed: "+str(a.name)+str(p))
   if ma.albedo_color!=mb.albedo_color:
    assert(ma.resource_name in ["WaitingRoom_plaster","WaitingRoom_dado"]);changed+=1
  checked+=1
 for a in old.find_children("*","Light3D",true,false):
  var b=now.get_node(old.get_path_to(a))
  for p in ["transform","light_color","light_energy","light_indirect_energy","light_size","shadow_enabled","shadow_blur","shadow_bias","shadow_normal_bias"]:assert(a.get(p)==b.get(p),"Light changed: "+str(a.name))
 var ea=old.get_node("IndoorEnvironment").environment;var eb=now.get_node("IndoorEnvironment").environment
 for p in ea.get_property_list():
  if p.usage&PROPERTY_USAGE_STORAGE and not p.name in ["resource_path","resource_name","resource_scene_unique_id"]:assert(ea.get(p.name)==eb.get(p.name),"Environment changed: "+str(p.name))
 assert(changed==58)
 print("WALL_SCOPE_VERIFIED ",checked," mesh poses unchanged; only 58 wall albedo colors changed; all light/environment, normal, roughness and texture settings retained")
 old.free();now.free();quit()

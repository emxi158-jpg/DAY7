extends SceneTree
func _initialize():call_deferred("run")
func run():
 var baseline=load("D:/yingyong/chatgpt/DAY7/_local_backup/surface_review_20261022_before/room_decor.scn").instantiate()
 var now=load("res://room_decor.scn").instantiate()
 var checked=0
 for a in baseline.find_children("*","MeshInstance3D",true,false):
  var b=now.get_node_or_null(baseline.get_path_to(a));assert(b!=null,"Lost existing object "+str(a.name));assert(a.transform==b.transform,"Moved original item "+str(a.name));assert(a.visible==b.visible,"Changed original visibility "+str(a.name));checked+=1
 var ea=baseline.get_node("IndoorEnvironment").environment;var eb=now.get_node("IndoorEnvironment").environment
 for p in ["tonemap_exposure","tonemap_mode","tonemap_agx_contrast","ambient_light_energy","ambient_light_color"]:assert(ea.get(p)==eb.get(p),"Global exposure or ambience changed")
 var old_lights=baseline.find_children("*","Light3D",true,false);var new_lights=now.find_children("*","Light3D",true,false);assert(old_lights.size()==new_lights.size(),"Added lamps")
 for a in old_lights:
  var b=now.get_node(baseline.get_path_to(a));assert(a.transform==b.transform,"Moved a lamp "+str(a.name));assert(a.light_color==b.light_color,"Changed lamp hue")
 var count=0
 for tile in now.get_node("Architecture/OldTileFloor").get_children():
  var m=tile.get_active_material(0);assert(m.roughness_texture.resource_path.ends_with("surface_review_20261022/floor_roughness.png"));count+=1
 assert(count==168)
 var source_sofa=baseline.find_child("Sofa_BackCushions",true,false);var target_sofa=now.find_child("Sofa_BackCushions",true,false)
 assert(source_sofa.mesh.get_surface_count()==target_sofa.mesh.get_surface_count());assert(source_sofa.mesh.get_aabb()==target_sofa.mesh.get_aabb())
 var board=load("res://assets/finished/board.tscn").instantiate()
 for k in range(1,7):
  var p=board.get_node("Notice%02d_Paper"%k);assert(p.visible and p.mesh.get_surface_count()==2);assert(p.mesh.get_aabb().size.z>.01)
 var locker=load("res://assets/finished/locker.tscn").instantiate();assert(locker.find_child("DoorFoldedSteelDetails",true,false)!=null);assert(locker.find_child("Locker_MirrorSurface",true,false)!=null)
 print("SURFACE_SCOPE_VERIFIED ",checked," original mesh poses and visibility preserved; 168 tiles; 6 physical printed sheets; existing lamps only; exposure and wall tint retained")
 board.free();locker.free();baseline.free();now.free();quit()

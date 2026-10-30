extends SceneTree
func _initialize():call_deferred("run")
func run():
 var w=load("res://main.tscn").instantiate();root.add_child(w);await process_frame
 var active=[]
 for n in w.find_children("*","Light3D",true,false):
  if n.is_visible_in_tree() and n.light_energy>0:
   active.append(str(n.name));assert(n.shadow_enabled)
 active.sort()
 assert(active==["ClockSconce_Warm","EntranceWindow_WarmTransmission","ExitWindow_CoolTransmission"])
 var e=w.get_node("RoomDecor/IndoorEnvironment").environment
 assert(e.ambient_light_energy==0 and is_equal_approx(e.tonemap_exposure,1.15))
 var gi=w.get_node("RoomDecor/BakedIndirectLight");assert(gi.environment_mode==LightmapGI.ENVIRONMENT_MODE_DISABLED and gi.light_data.get_user_count()>0)
 for angle in [false,true]:
  w.actors.exit.set_exit_open(angle,true);w.actors.exit._process(0.)
  var a=w.actors.exit.part("ExitDoor_CloserArmA");var b=w.actors.exit.part("ExitDoor_CloserArmB")
  assert((a.transform*Vector3.UP).distance_to(b.position)<.0001)
  assert(a.mesh.get_aabb().size.y<1.02 and b.mesh.get_aabb().size.y<1.02)
 var report={"active_sources":active,"ambient":e.ambient_light_energy,"fixed_exposure":e.tonemap_exposure,"baked_users":gi.light_data.get_user_count(),"closer_connected_open_and_closed":true}
 FileAccess.open("res://previews/three_sources_20261024/verification.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
 print("THREE_PRACTICAL_SOURCE_CHECK_PASSED ",JSON.stringify(report));w.free();quit()

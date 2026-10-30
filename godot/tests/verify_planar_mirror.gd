extends SceneTree
func _initialize():call_deferred("run")
func run():
 var w=load("res://main.tscn").instantiate();root.add_child(w);await process_frame
 var mirror=w.get_node("RoomDecor/Architecture/FurnitureAndShell/Mirror_assembly/Mirror_glass")
 var driver=mirror.get_node_or_null("PlanarReflection")
 if driver==null:print("FAIL mirror has no view-dependent reflection renderer");w.free();quit(1);return
 var cam=w.player.camera;cam.global_position=Vector3(2.1,1.7,-.55);driver.update_view()
 var center=mirror.global_position;var normal=mirror.global_basis.z.normalized();var eye=driver.reflection_camera.global_position
 assert(absf((eye-center).dot(normal)+(cam.global_position-center).dot(normal))<.0001)
 cam.look_at(center);driver.update_view()
 assert(driver.viewport.render_target_update_mode==SubViewport.UPDATE_ALWAYS)
 var first_eye=driver.reflection_camera.global_position
 cam.global_position+=Vector3(0,.1,.2);cam.look_at(center);driver.update_view()
 assert(driver.reflection_camera.global_position.distance_to(first_eye)>.2)
 var distance=maxf(.001,(cam.global_position-center).dot(normal))
 assert(is_equal_approx(driver.reflection_camera.near,distance+.002))
 assert(driver.reflection_camera.cull_mask & (1<<17)==0)
 cam.look_at(cam.global_position+normal);driver.update_view()
 assert(driver.viewport.render_target_update_mode==SubViewport.UPDATE_DISABLED)
 print("MIRROR_GEOMETRY_CHECK_PASS reflected eye, parallax, clipping, self exclusion, offscreen suspension");w.free();quit()

extends SceneTree
func _initialize()->void:call_deferred("run")
func run()->void:
	var world=load("res://main.tscn").instantiate()
	root.add_child(world)
	await process_frame
	await process_frame
	var issues=[]
	var foot=world.get_node("RoomDecor/Architecture/FurnitureAndShell/Conduit_wall_foot_008")
	var foot_bounds=foot.global_transform*foot.mesh.get_aabb()
	if foot_bounds.end.x<3.85 or foot_bounds.end.x>3.856:issues.append("upper conduit mount not attached to wall")
	var groups=world.get_meta("exit_light_groups")
	var header=groups.sign.get_node("Sign_HeaderWash")
	if header.light_color.s>.40 or header.light_energy>.05:issues.append("sign wash too saturated/concentrated")
	if groups.cold.get_node("Window_FloorReturn").light_energy>0:issues.append("floor return aimed at whole door")
	var transmission=groups.cold.get_node("Window_SoftFloorTransmission")
	if transmission.light_specular>.25 or transmission.spot_angle_attenuation<2:issues.append("floor projection too hard/specular")
	var model=world.actors.exit.model
	var second=model.find_child("ExitDoor_CloserArmB",true,false)
	var end=model.to_global(second.position+second.basis*Vector3.UP)
	var body=model.find_child("ExitDoor_CloserBody",true,false)
	var bounds=body.global_transform*body.mesh.get_aabb()
	var nearest=Vector3(clampf(end.x,bounds.position.x,bounds.end.x),clampf(end.y,bounds.position.y,bounds.end.y),clampf(end.z,bounds.position.z,bounds.end.z))
	if end.distance_to(nearest)>.02:issues.append("closer link disconnected from body by "+str(end.distance_to(nearest)))
	for degrees in [0,45,105,0]:
		world.actors.exit.part("ExitDoor_Leaf").rotation.y=deg_to_rad(degrees)
		await process_frame
		await process_frame
		var endpoint=model.to_global(second.position+second.basis*Vector3.UP)
		var local_end=body.to_local(endpoint)
		var box=body.mesh.get_aabb()
		var closest=Vector3(clampf(local_end.x,box.position.x,box.end.x),clampf(local_end.y,box.position.y,box.end.y),clampf(local_end.z,box.position.z,box.end.z))
		if local_end.distance_to(closest)>.02:issues.append("closer disconnected at "+str(degrees))
	for title in ["ExitDoor_CloserArmA","ExitDoor_CloserArmB"]:
		var arm=model.find_child(title,true,false)
		if not arm.is_visible_in_tree() or arm.cast_shadow!=GeometryInstance3D.SHADOW_CASTING_SETTING_ON:issues.append("closer was hidden instead of repaired")
	var face=model.find_child("ExitSign_Face",true,false)
	if face.global_basis.y.dot(Vector3.UP)<.999:issues.append("sign face is tilted")
	if issues.size()>0:
		printerr("EXIT_ANOMALY_CHECK_FAILED ",issues)
		world.free()
		quit(1)
		return
	print("EXIT_ANOMALY_CHECK_PASSED no new lights; restrained sources; closer connected; sign level")
	world.free()
	quit()
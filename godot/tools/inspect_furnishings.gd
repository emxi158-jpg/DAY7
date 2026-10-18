extends SceneTree
func _initialize()->void:call_deferred("run")
func run()->void:
	var room=load("res://room_decor.scn").instantiate()
	root.add_child(room)
	for n in room.find_children("*","MeshInstance3D",true,false):
		var label=String(n.name).to_lower()
		var bounds=n.global_transform*n.mesh.get_aabb()
		var c=bounds.get_center()
		if (c.x< -3.1 and c.z< -1.95 and c.y<1.6 and bounds.size.x<.5) or (c.x>.7 and c.x<2.5 and c.z< -1 and c.y>2.35):
			if n.visible:print("ROOM_PART ",n.name," bbox=",n.global_transform*n.mesh.get_aabb())
	var locker=load("res://assets/finished/locker.tscn").instantiate()
	root.add_child(locker)
	for n in locker.find_children("*","MeshInstance3D",true,false):
		if String(n.name) in ["Locker_Body","Locker_BackPanel","Locker_Door","Locker_MirrorSurface","Locker_TopShelf"]:
			print("LOCKER_PART ",n.name," transform=",n.transform," bbox=",n.global_transform*n.mesh.get_aabb())
			if n.name=="Locker_Door":
				var m=n.get_active_material(0)
				print("LOCKER_MATERIAL ",m.resource_name," color=",m.albedo_color," texture=",m.albedo_texture.resource_path if m.albedo_texture else "NONE")
	quit()

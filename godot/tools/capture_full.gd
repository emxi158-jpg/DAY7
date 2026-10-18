extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var world=load("res://main.tscn").instantiate()
	root.add_child(world)
	await process_frame
	if "--no-shadow-mesh" in OS.get_cmdline_user_args():
		for n in world.find_children("*","MeshInstance3D",true,false):
			if n.mesh is ArrayMesh:n.mesh.shadow_mesh=null
	if "--spot-ceiling" in OS.get_cmdline_user_args():
		var original=world.get_node("RoomDecor/Lighting/Fluorescent_Main")
		original.shadow_enabled=false
		original.light_energy=.12
		var spot=SpotLight3D.new()
		world.add_child(spot)
		spot.global_position=original.global_position
		spot.look_at(original.global_position+Vector3.DOWN)
		spot.spot_angle=85
		spot.spot_range=8
		spot.spot_angle_attenuation=.15
		spot.light_color=original.light_color
		spot.light_energy=1.5
		spot.light_size=.08
		spot.shadow_enabled=true
		spot.shadow_bias=.04
		spot.shadow_normal_bias=.7
	if "--no-shadows" in OS.get_cmdline_user_args():
		for light in world.find_children("*","Light3D",true,false):light.shadow_enabled=false
	world.player.set_physics_process(false)
	world.player.set_process_unhandled_input(false)
	for n in world.get_children():
		if n is CanvasLayer:n.hide()
	Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
	var camera=world.player.camera
	var previews=[
		["01_完整等待室",Vector3(-2.7,1.68,3.05),Vector3(.0,1.42,-1.05),65.0],
		["02_挂钟与壁灯",Vector3(.13,2.23,-.95),Vector3(.13,2.32,-2.78),42.0],
		["03_地板与光感",Vector3(.20,.65,3.55),Vector3(.0,.02,1.75),58.0],
		["04_公告板",Vector3(-1.4,2.0,-.95),Vector3(-1.4,1.97,-2.76),47.0],
		["05_天花双管灯",Vector3(-.65,2.18,1.12),Vector3(-.65,2.97,-.12),49.0],
		["06_饮水机",Vector3(-2.88,1.00,-.63),Vector3(-3.35,.79,-2.22),53.0],
		["07_双柜布局",Vector3(.65,1.55,.12),Vector3(1.99,1.22,-2.35),57.0]]
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://previews"))
	for spec in previews:
		camera.global_position=spec[1]
		camera.look_at(spec[2])
		camera.fov=spec[3]
		for i in range(130):await process_frame
		await RenderingServer.frame_post_draw
		var image=root.get_texture().get_image()
		var output="res://previews/"+("diag_" if "--no-shadows" in OS.get_cmdline_user_args() else "")+spec[0]+".png"
		var saved=ERR_BUSY
		for attempt in range(4):
			saved=image.save_png(output)
			if saved==OK:break
			for frame in range(10):await process_frame
		assert(saved==OK,"预览截图保存失败："+output)
		print("CAPTURED ",spec[0])
	var report={"meshes":world.find_children("*","MeshInstance3D",true,false).size(),"floor_tiles":world.get_node("RoomDecor/Architecture/OldTileFloor").get_child_count(),"baked_users":world.get_node("RoomDecor/BakedIndirectLight").light_data.get_user_count(),"renderer":RenderingServer.get_rendering_device().get_device_name(),"loops":4}
	FileAccess.open("res://full_room_verification.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	print("FULL_ROOM_CAPTURED ",JSON.stringify(report))
	world.queue_free()
	await process_frame
	quit()

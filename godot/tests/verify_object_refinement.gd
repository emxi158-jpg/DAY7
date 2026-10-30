extends SceneTree
func _initialize()->void:call_deferred("run")
func run()->void:
	assert(load("res://tools/refine_clock_board.gd")!=null)
	var world=load("res://main.tscn").instantiate();root.add_child(world)
	await process_frame
	world.player.set_physics_process(false)
	var clock=world.actors.clock
	clock.set_time(17,30)
	assert(is_equal_approx(clock.part("Clock_HourHand").rotation.z,-TAU*5.5/12))
	assert(is_equal_approx(clock.part("Clock_MinuteHand").rotation.z,-PI))
	var h=clock.part("Clock_HourHand").rotation.z
	var second=clock.part("Clock_SecondHand")
	clock.part("Clock_MinuteHand").rotation.z=.4
	assert(is_equal_approx(clock.part("Clock_HourHand").rotation.z,h) and is_zero_approx(second.rotation.z))
	for i in range(1,13):
		var number=clock.part("Clock_Number_%02d"%i)
		assert(number.mesh.text==str(i))
		assert(is_equal_approx(Vector2(number.position.x,number.position.y).length(),.229))
	assert(second.mesh.get_aabb().size.z>.001)
	assert(clock.part("Clock_Face").mesh.get_aabb().size.z>=.002)
	assert(clock.part("Clock_HourHand").position.z>clock.part("Clock_Face").position.z)
	assert(clock.part("Clock_Glass").position.z>second.position.z)
	assert(clock.model.find_children("Clock_SecondHand","MeshInstance3D",true,false).size()==1)
	assert(world.enlarged_clock.part("Clock_Frame").mesh==clock.part("Clock_Frame").mesh)
	assert(world.enlarged_clock.part("Clock_SecondHand").mesh==second.mesh)
	var board=world.actors.board
	for i in range(3):
		board.set_note_state(i)
		assert(board.note_label.text==["17:3","17:30","18:40"][i])
	for i in range(1,7):
		var sheet=board.model.get_node("Notice%02d_Paper"%i)
		assert(sheet.is_visible_in_tree() and sheet.mesh.get_surface_count()==2)
		assert(sheet.mesh.get_aabb().size.z>.002)
		assert(sheet.get_active_material(0).albedo_texture!=null)
	var baseline=load("D:/yingyong/chatgpt/DAY7/_local_backup/objects_20261021_before/room_decor.scn").instantiate()
	var room=world.get_node("RoomDecor")
	for old in baseline.find_children("*","Light3D",true,false):
		var current=room.get_node(baseline.get_path_to(old))
		for property in ["transform","light_energy","light_color","light_indirect_energy"]:assert(old.get(property)==current.get(property),"Lighting changed: "+old.name)
	var saved_room=load("res://room_decor.scn").instantiate()
	var checked=0;var wall_changes=0
	for old in baseline.find_children("*","MeshInstance3D",true,false):
		var current=saved_room.get_node(baseline.get_path_to(old))
		assert(old.transform==current.transform,"Other furniture moved")
		for i in range(old.mesh.get_surface_count()):
			var a=old.get_active_material(i);var b=current.get_active_material(i)
			if not a is BaseMaterial3D:continue
			for property in ["normal_texture","normal_scale","roughness","albedo_color","metallic"]:assert(a.get(property)==b.get(property),"Existing surface changed: "+old.name)
			if a.albedo_texture!=b.albedo_texture:assert(a.resource_name=="WaitingRoom_plaster");wall_changes+=1
		checked+=1
	assert(wall_changes==6)
	print("OBJECT_REFINEMENT_VERIFIED original clock controls and clues, 12 accurate numerals, linked enlarged clock, 7 sheets, unchanged light poses/energies and ",checked," room mesh poses; only 6 plaster albedos calmed")
	saved_room.free();baseline.free();world.free();quit()
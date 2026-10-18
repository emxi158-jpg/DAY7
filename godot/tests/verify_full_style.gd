extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	assert(ProjectSettings.get_setting("rendering/renderer/rendering_method","forward_plus") == "forward_plus", "整景必须使用 Forward+")
	assert(ResourceLoader.exists("res://room_decor.scn"), "整景照明场景尚未生成")
	var world = load("res://main.tscn").instantiate()
	root.add_child(world)
	await process_frame
	assert(world.loading_ok)
	var room = world.get_node("RoomDecor")
	assert(room.get_node("BakedIndirectLight").light_data.get_user_count() > 0, "间接光必须真正烘焙")
	assert(room.get_node("Lighting/ClockSconce_Warm").light_energy > 0)
	assert(room.get_node("Architecture/OldTileFloor").get_child_count() >= 150)
	for node in room.find_children("*","MeshInstance3D",true,false):
		if node.is_visible_in_tree() and node.mesh is ArrayMesh:
			assert(node.mesh.shadow_mesh==null,"导入阴影代理不能重新引入脱离模型的黑块")
	var clock = world.actors.clock
	for digit in range(1,13):
		var n = clock.model.find_child("Clock_Number_%02d" % digit,true,false)
		assert(n is MeshInstance3D and n.mesh is TextMesh)
		assert(n.mesh.font_size >= 64 and n.mesh.pixel_size >= .0007)
	assert(clock.part("Clock_Face").material_override.roughness > .85)
	assert(world.actors.board.note_states == ["17:3","17:30","18:40"])
	world.open_clock_panel(clock)
	assert(world.clock_panel_open)
	world.clock_selector.select(1)
	world._clock_hand_selected(1)
	var h=clock.hour_value
	world.clock_value.value=30
	assert(clock.minute_value==30 and clock.hour_value==h)
	world.clock_selector.select(0)
	world._clock_hand_selected(0)
	assert(clock.hour_value==h and clock.minute_value==30,"切换钟针不能改变已设时间")
	world.clock_value.value=17
	assert(clock.hour_value==17 and clock.minute_value==30)
	world.close_clock_panel()
	assert(not world.clock_panel_open)
	clock.set_time(17,30)
	assert(is_equal_approx(clock.part("Clock_MinuteHand").rotation.z,-PI))
	print("FULL_ROOM_STYLE_PASSED")
	world.queue_free()
	await process_frame
	quit()

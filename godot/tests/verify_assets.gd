extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var packed = load("res://main.tscn")
	assert(packed != null)
	var world = packed.instantiate()
	root.add_child(world)
	await process_frame
	await physics_frame
	assert(world.loading_ok)
	var clock = world.actors.clock
	var minute = clock.part("Clock_MinuteHand")
	var hour = clock.part("Clock_HourHand")
	clock.set_time(17,30)
	assert(is_equal_approx(minute.rotation.z,-PI))
	assert(is_equal_approx(hour.rotation.z,-TAU*5.5/12.0))
	var old_hour = hour.rotation.z
	minute.rotation.z = 0.3
	assert(is_equal_approx(hour.rotation.z,old_hour))
	world.set_loop(2)
	var locker = world.actors.locker
	locker.set_locker_open(true,true)
	assert(absf(locker.part("Locker_Door").rotation.y)>1.5)
	assert(locker.part("Locker_MirrorSurface") is MeshInstance3D)
	locker.set_gateway_active(true)
	await physics_frame
	assert(locker.mirror_block.disabled)
	# Walk a real 0.50 m diameter / 1.75 m high capsule through the opened cabinet.
	# This catches accidental solid AABB colliders or a hidden wall behind the mirror.
	world.player.set_physics_process(false)
	world.player.global_position = locker.to_global(Vector3(0,0.06,1.35))
	world.player.velocity = Vector3.ZERO
	await physics_frame
	var entered = false
	for step in range(120):
		world.player.velocity = Vector3(0,-0.3,-2.5)
		world.player.move_and_slide()
		await physics_frame
		if step%30 == 0:
			var hit_names = []
			for hit_index in range(world.player.get_slide_collision_count()):
				hit_names.append(str(world.player.get_slide_collision(hit_index).get_collider().get_parent().name))
			print("CAPSULE_STEP ",step," local=",locker.to_local(world.player.global_position)," collision=",hit_names)
		if world.infinite_space.active:
			entered = true
			break
	if not entered:
		printerr("Player capsule was blocked before entering the locker mirror portal")
		quit(1)
		return
	world.reset_player()
	world.player.set_physics_process(true)
	world.set_loop(3)
	locker.detach_handle()
	assert(locker.handle_detached)
	assert(locker.part("Locker_Handle").get_parent() is RigidBody3D)
	locker.pickup_handle(world.player.hand_socket)
	assert(locker.part("Locker_Handle").get_parent()==world.player.hand_socket)
	assert(locker.holding_handle)
	var sink = world.actors.sink
	sink.set_water(true)
	assert(sink.water_particles.emitting and sink.water_jet.visible)
	sink.break_faucet()
	assert(sink.damaged and not sink.water_on)
	assert(sink.part("Faucet_Broken").visible and not sink.part("Faucet_Normal").visible)
	var pointer = world.actors.pointer
	pointer.select_target(1)
	assert(world.gateway_target=="exit_door")
	world.set_loop(2)
	world.actors.exit.set_exit_open(true,true)
	assert(world.infinite_space.active)
	assert(world.infinite_space.modules.size()==7)
	await physics_frame
	world.player.set_physics_process(false)
	world.player.global_position = world.actors.exit.to_global(Vector3(0,0.08,0.80))
	var furthest_x = world.player.global_position.x
	for step in range(140):
		world.player.velocity = Vector3(2.5,-0.3,0)
		world.player.move_and_slide()
		await physics_frame
		furthest_x = maxf(furthest_x,world.player.global_position.x)
		if furthest_x > 7.65: break
	if furthest_x <= 7.65:
		printerr("Exit walking test stopped at ",world.player.global_position)
		quit(1)
		return
	world.reset_player()
	world.player.set_physics_process(true)
	world.set_loop(4)
	var board = world.actors.board
	var transform_before = board.part("KeyNote_Assembly").global_transform
	for i in range(3):
		board.set_note_state(i)
		assert(board.note_label.text==["17:3","17:30","18:40"][i])
		assert(board.part("KeyNote_Assembly").global_transform==transform_before)
	assert(world.enlarged_clock.scale==Vector3.ONE*3.2)
	assert(world.enlarged_clock.part("Clock_Frame").mesh == clock.part("Clock_Frame").mesh)
	var report = {"clock_independent_hands":true,"locker_opens":true,"mirror_passable_in_loop2":true,"player_capsule_actually_walked_through_locker":true,
		"handle_detaches_and_can_be_held":true,"godot_water_and_broken_state":true,
		"pointer_selects_gateway":true,"independent_repeated_rooms":7,"player_walked_through_exit_into_repeated_rooms":true,"same_clock_scaled":true,"single_note_three_texts":true}
	var file = FileAccess.open("res://godot_verification.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"  "))
	print("V02_GODOT_TESTS_PASSED ",JSON.stringify(report))
	world.queue_free()
	await process_frame
	quit(0)

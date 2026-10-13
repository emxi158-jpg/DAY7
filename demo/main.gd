extends Node3D

const LIMIT := 600.0
var elapsed := 0.0
var clock_hour := 4
var cabinet_number := 4
var loop_number := 1
var unlocked := false
var transitioning := false
var fast := false
var camera: Camera3D
var player: Node3D
var back_wall: Node3D
var left_wall: Node3D
var right_wall: Node3D
var ceiling: Node3D
var hour_hand: Node3D
var cabinet_label: Label3D
var door: Node3D
var timer_label: Label3D
var hud: Label
var overlay: Label
var interactables: Array[Node3D] = []
var focused: Node3D
var pitch := 0.0
var sound: AudioStreamPlayer
var tick_playback: AudioStreamGeneratorPlayback
var tick_phase := 0.0
var tick_remaining := 0
var tick_index := -1
var warp_strength := 0.0
var warp_materials: Array[ShaderMaterial] = []
var attached_labels: Array[Dictionary] = []
var attached_lights: Array[Dictionary] = []
var preview_stage := -1
const WARP_SHADER = preload("res://space_warp.gdshader")
const Warp = preload("res://space_warp.gd")

func warp_material(color: Color, floor_pattern := false) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = WARP_SHADER
	mat.set_shader_parameter("base_color", color)
	mat.set_shader_parameter("floor_tiles", floor_pattern)
	warp_materials.append(mat)
	return mat

func make_shell() -> void:
	var surfaces := [
		[Vector3(-5, 0, -5), Vector3(10, 0, 0), Vector3(0, 0, 10), Vector3.UP, Color("454039"), true],
		[Vector3(-5, 3.8, -5), Vector3(10, 0, 0), Vector3(0, 0, 10), Vector3.DOWN, Color("393b35"), false],
		[Vector3(-5, 0, -5), Vector3(10, 0, 0), Vector3(0, 3.8, 0), Vector3.BACK, Color("625f52"), false],
		[Vector3(-5, 0, 5), Vector3(10, 0, 0), Vector3(0, 3.8, 0), Vector3.FORWARD, Color("4a504d"), false],
		[Vector3(-5, 0, -5), Vector3(0, 0, 10), Vector3(0, 3.8, 0), Vector3.RIGHT, Color("4a504d"), false],
		[Vector3(5, 0, -5), Vector3(0, 0, 10), Vector3(0, 3.8, 0), Vector3.LEFT, Color("4a504d"), false]
	]
	for surface in surfaces:
		var mesh := MeshInstance3D.new()
		mesh.mesh = Warp.shell_face(surface[0], surface[1], surface[2], surface[3])
		mesh.material_override = warp_material(surface[4], surface[5])
		mesh.extra_cull_margin = 4.0
		add_child(mesh)
	# Continuous cornice / skirting give the eye readable warped boundaries.
	for y in [0.10, 3.64]:
		block(self, Vector3(0, y, -4.96), Vector3(10, 0.09, 0.08), Color("272c28"))
		block(self, Vector3(0, y, 4.96), Vector3(10, 0.09, 0.08), Color("272c28"))
		block(self, Vector3(-4.96, y, 0), Vector3(0.08, 0.09, 10), Color("272c28"))
		block(self, Vector3(4.96, y, 0), Vector3(0.08, 0.09, 10), Color("272c28"))

func remember_attachments(node: Node) -> void:
	if node is Label3D:
		attached_labels.append({"node": node, "base": node.global_transform})
	if node is Light3D:
		attached_lights.append({"node": node, "base": node.global_position})
	for child in node.get_children():
		remember_attachments(child)

func update_camera_position() -> void:
	camera.global_position = Warp.point(player.position + Vector3(0, 1.65, 0), warp_strength)

func target_position(node: Node3D) -> Vector3:
	return Warp.point(node.global_position, warp_strength)

func block(parent: Node3D, pos: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	box.subdivide_width = maxi(1, int(ceil(size.x / 0.25)))
	box.subdivide_height = maxi(1, int(ceil(size.y / 0.25)))
	box.subdivide_depth = maxi(1, int(ceil(size.z / 0.25)))
	mesh.mesh = box
	mesh.material_override = warp_material(color)
	mesh.extra_cull_margin = 4.0
	parent.add_child(mesh)
	mesh.position = pos
	return mesh

func label3(parent: Node3D, pos: Vector3, text_value: String, font_size := 44) -> Label3D:
	var label := Label3D.new()
	label.text = text_value
	label.font_size = font_size
	label.pixel_size = 0.006
	label.outline_size = 6
	parent.add_child(label)
	label.position = pos
	return label

func region(pos: Vector3) -> Node3D:
	var node := Node3D.new()
	add_child(node)
	node.position = pos
	return node

func target(parent: Node3D, pos: Vector3, kind: String, radius: float) -> Node3D:
	var node := Node3D.new()
	parent.add_child(node)
	node.position = pos
	node.set_meta("kind", kind)
	node.set_meta("radius", radius)
	interactables.append(node)
	return node

func _ready() -> void:
	var env := WorldEnvironment.new()
	var settings := Environment.new()
	settings.background_mode = Environment.BG_COLOR
	settings.background_color = Color(0.025, 0.03, 0.04)
	settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color = Color(0.65, 0.7, 0.8)
	settings.ambient_light_energy = 0.32
	env.environment = settings
	add_child(env)
	make_shell()
	back_wall = region(Vector3(0, 0, -5))
	left_wall = region(Vector3(-5, 0, 0))
	right_wall = region(Vector3(5, 0, 0))
	ceiling = region(Vector3(0, 3.8, 0))
	# Clock and cabinet share the rear wall so remote changes remain visible.
	var clock := target(back_wall, Vector3(-1.5, 2.65, 0.3), "clock", 0.7)
	var face := MeshInstance3D.new()
	var disc := CylinderMesh.new()
	disc.top_radius = 0.52
	disc.bottom_radius = 0.52
	disc.height = 0.09
	face.mesh = disc
	face.rotation.x = PI / 2
	disc.rings = 8
	face.material_override = warp_material(Color("d8cba6"))
	face.extra_cull_margin = 4.0
	clock.add_child(face)
	for n in range(1, 13):
		var a := n * TAU / 12.0
		label3(clock, Vector3(sin(a) * 0.41, cos(a) * 0.41, 0.065), str(n), 21)
	hour_hand = Node3D.new()
	clock.add_child(hour_hand)
	block(hour_hand, Vector3(0, 0.14, 0.085), Vector3(0.035, 0.28, 0.018), Color("202425"))
	block(clock, Vector3(0, 0.2, 0.07), Vector3(0.02, 0.4, 0.018), Color("202425"))
	label3(clock, Vector3(0, -0.7, 0.08), "挂钟 · 转动旋钮", 25)
	var cabinet := target(back_wall, Vector3(1.4, 1.25, 0.65), "cabinet", 1.05)
	block(cabinet, Vector3.ZERO, Vector3(1.1, 2.5, 0.8), Color("434e48"))
	block(cabinet, Vector3(0, 0, 0.42), Vector3(0.98, 2.36, 0.04), Color("59675e"))
	for y in range(4):
		block(cabinet, Vector3(0, 0.75 + y * 0.09, 0.45), Vector3(0.65, 0.025, 0.02), Color("242c29"))
	block(cabinet, Vector3(0.33, 0, 0.47), Vector3(0.06, 0.25, 0.06), Color("b8ab7b"))
	cabinet_label = label3(cabinet, Vector3(0, 0.25, 0.48), "4", 80)
	label3(cabinet, Vector3(0, -0.65, 0.48), "储物柜 · 调节拨盘", 23)
	# Door stays attached to its own folding wall.
	var exit_root := target(right_wall, Vector3(-0.3, 1.4, -1.5), "door", 1.4)
	exit_root.rotation.y = -PI / 2
	block(exit_root, Vector3.ZERO, Vector3(1.7, 2.8, 0.2), Color("191f24"))
	door = Node3D.new()
	exit_root.add_child(door)
	block(door, Vector3.ZERO, Vector3(1.45, 2.6, 0.25), Color("334448"))
	block(door, Vector3(0.35, 0.45, 0.15), Vector3(0.25, 0.95, 0.025), Color("94b2b0"))
	label3(exit_root, Vector3(0, 1.7, 0.15), "EXIT / 7", 48).modulate = Color("76ffca")
	timer_label = label3(exit_root, Vector3(0, -0.55, 0.18), "", 28)
	# Sparse waiting-room furniture: preserve clear paths around the center.
	block(self, Vector3(-3, 0.45, -3.5), Vector3(2.5, 0.6, 1), Color("3f3028"))
	block(self, Vector3(-3, 0.9, -3.95), Vector3(2.5, 0.8, 0.2), Color("4c392e"))
	block(self, Vector3(-2.7, 0.65, -1.8), Vector3(1.9, 0.12, 0.9), Color("6d5439"))
	for x in [-3.4, -2.0]:
		for z in [-2.1, -1.5]:
			block(self, Vector3(x, 0.3, z), Vector3(0.08, 0.6, 0.08), Color("302c29"))
	block(back_wall, Vector3(-3.4, 2.3, 0.25), Vector3(1.3, 1, 0.1), Color("715538"))
	label3(back_wall, Vector3(-3.4, 2.3, 0.32), "等待须知\n请在十分钟内离开\n出口要求：7", 25)
	for pos in [Vector3(-1.5, 3.2, -3.6), Vector3(1, 3.2, 0)]:
		var light := OmniLight3D.new()
		add_child(light)
		light.position = pos
		light.light_color = Color("ffd6a0")
		light.light_energy = 1.6
		light.omni_range = 9
		block(ceiling, Vector3(pos.x, -0.18, pos.z), Vector3(1.1, 0.08, 0.25), Color("e0d1a8"))
	player = Node3D.new()
	add_child(player)
	camera = Camera3D.new()
	player.add_child(camera)
	camera.position.y = 1.65
	camera.fov = 65
	var canvas := CanvasLayer.new()
	add_child(canvas)
	hud = Label.new()
	canvas.add_child(hud)
	hud.position = Vector2(24, 20)
	hud.add_theme_font_size_override("font_size", 20)
	var crosshair := Label.new()
	canvas.add_child(crosshair)
	crosshair.text = "+"
	crosshair.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	overlay = Label.new()
	canvas.add_child(overlay)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	overlay.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	overlay.add_theme_font_size_override("font_size", 64)
	sound = AudioStreamPlayer.new()
	var stream := AudioStreamGenerator.new()
	stream.mix_rate = 22050
	stream.buffer_length = 0.12
	sound.stream = stream
	sound.volume_db = -18
	add_child(sound)
	if DisplayServer.get_name() != "headless" and "--capture-stages" not in OS.get_cmdline_user_args():
		sound.play()
		tick_playback = sound.get_stream_playback()
	remember_attachments(self)
	reset_room()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if "--smoke-test" in OS.get_cmdline_user_args():
		call_deferred("smoke_test")
	if "--capture-stages" in OS.get_cmdline_user_args():
		call_deferred("capture_stages")

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and not transitioning:
		player.rotation.y -= event.relative.x * 0.0025
		pitch = clampf(pitch - event.relative.y * 0.0025, -1.3, 1.3)
		camera.rotation.x = pitch
	if event is InputEventMouseButton and event.pressed and not transitioning:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_ESCAPE: Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			KEY_F:
				preview_stage = -1
				fast = not fast
			KEY_1, KEY_2, KEY_3, KEY_4:
				preview_stage = event.keycode - KEY_1
				elapsed = [0.0, 200.0, 400.0, 570.0][preview_stage]
				update_fold()
			KEY_R:
				if not transitioning:
					loop_number = 1
					reset_room()
			KEY_E:
				if focused != null and not transitioning and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
					interact(str(focused.get_meta("kind")))

func _process(delta: float) -> void:
	if tick_playback != null:
		var new_tick := int(elapsed * (1.0 + elapsed / LIMIT * 2.0))
		if new_tick != tick_index:
			tick_index = new_tick
			tick_remaining = 1100
		var available := tick_playback.get_frames_available()
		for i in range(available):
			var value := 0.0
			if tick_remaining > 0 and not transitioning:
				value = sin(tick_phase) * float(tick_remaining) / 1100.0 * 0.35
				tick_phase += TAU * 1700.0 / 22050.0
				tick_remaining -= 1
			tick_playback.push_frame(Vector2(value, value))
	if transitioning:
		return
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var axis := Vector3(float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A)), 0, float(Input.is_physical_key_pressed(KEY_S)) - float(Input.is_physical_key_pressed(KEY_W)))
		var next := player.position + player.basis * axis.normalized() * delta * 3.0
		# Visual folds have stable navigation boundaries for this prototype.
		next.x = clampf(next.x, -4.1, 4.1)
		next.z = clampf(next.z, -4.0, 4.2)
		if not (next.x < -1.6 and next.z < -1.1):
			player.position = next
	if preview_stage < 0:
		elapsed = minf(elapsed + delta * (60.0 if fast else 1.0), LIMIT)
	update_fold()
	update_camera_position()
	focused = pick_target()
	var remaining := int(ceil(LIMIT - elapsed))
	timer_label.text = "剩余 %02d:%02d\n%s" % [remaining / 60, remaining % 60, "已解锁 · E 穿过出口" if unlocked else "LOCKED"]
	var prompt := "靠近并对准道具"
	if focused != null:
		var names := {"clock": "挂钟 · E 转动", "cabinet": "储物柜 · E 调节", "door": "出口 · E 进入"}
		prompt = names[str(focused.get_meta("kind"))]
	hud.text = "LOOP %d   /   操作错位\nWASD 移动 · 鼠标观察 · E 操作 · Esc 释放鼠标\nF 加速折叠（%s） · R 重试\n1–4 定格观察空间阶段\n\n%s" % [loop_number, "60倍" if fast else "正常", prompt]
	if elapsed >= LIMIT:
		finish(false)

func pick_target() -> Node3D:
	var best: Node3D = null
	var best_alignment := 0.96
	var forward := -camera.global_basis.z
	for node in interactables:
		var offset := target_position(node) - camera.global_position
		if offset.length() > 3.5:
			continue
		var alignment := forward.dot(offset.normalized())
		if alignment > best_alignment:
			best = node
			best_alignment = alignment
	return best

func interact(kind: String) -> void:
	match kind:
		"clock":
			cabinet_number = cabinet_number % 12 + 1
			cabinet_label.text = str(cabinet_number)
		"cabinet":
			clock_hour = clock_hour % 12 + 1
			hour_hand.rotation.z = -clock_hour * TAU / 12.0
			unlocked = clock_hour == 7
			door.position.x = -1.2 if unlocked else 0.0
		"door":
			if unlocked:
				finish(true)

func update_fold() -> void:
	warp_strength = pow(elapsed / LIMIT, 1.25)
	for mat in warp_materials:
		mat.set_shader_parameter("strength", warp_strength)
	for item in attached_labels:
		var original: Transform3D = item["base"]
		var warped_basis := Warp.jacobian(original.origin, warp_strength) * original.basis
		item["node"].global_transform = Transform3D(warped_basis, Warp.point(original.origin, warp_strength))
	for item in attached_lights:
		item["node"].global_position = Warp.point(item["base"], warp_strength)

func reset_room() -> void:
	elapsed = 0.0
	clock_hour = 4
	cabinet_number = 4
	cabinet_label.text = "4"
	hour_hand.rotation.z = -4 * TAU / 12.0
	unlocked = false
	door.position.x = 0.0
	player.position = Vector3(0, 0, 2.5)
	player.rotation = Vector3.ZERO
	pitch = 0.0
	camera.rotation = Vector3.ZERO
	fast = false
	preview_stage = -1
	focused = null
	update_fold()
	update_camera_position()

func finish(success: bool) -> void:
	transitioning = true
	overlay.text = "CLEAR" if success else "空间失控"
	await get_tree().create_timer(1.3).timeout
	RenderingServer.set_default_clear_color(Color.BLACK)
	player.visible = false
	camera.cull_mask = 0
	overlay.text = "RESET"
	await get_tree().create_timer(1.2).timeout
	loop_number = loop_number + 1 if success else 1
	reset_room()
	camera.cull_mask = 1048575
	player.visible = true
	overlay.text = ""
	transitioning = false

func smoke_test() -> void:
	# Verify the rendered target positions can be reached by the actual aim picker.
	for node in interactables:
		player.position = node.global_position + Vector3(0, -1.65, 2.0)
		if str(node.get_meta("kind")) == "door":
			player.position = node.global_position + Vector3(-2.0, -1.65, 0)
		update_camera_position()
		camera.look_at(target_position(node))
		if pick_target() != node:
			push_error("Unreachable interaction target: " + str(node.get_meta("kind")))
			get_tree().quit(5)
			return
	reset_room()
	elapsed = 500.0
	update_fold()
	if not check_warp():
		get_tree().quit(6)
		return
	reset_room()
	interact("clock")
	interact("clock")
	interact("clock")
	if cabinet_number != 7 or clock_hour != 4 or unlocked:
		push_error("Clock/cabinet mismatch failed")
		get_tree().quit(1)
		return
	interact("cabinet")
	interact("cabinet")
	interact("cabinet")
	if clock_hour != 7 or not unlocked:
		get_tree().quit(2)
		return
	interact("door")
	await get_tree().create_timer(2.8).timeout
	if loop_number != 2 or clock_hour != 4 or cabinet_number != 4 or unlocked:
		get_tree().quit(3)
		return
	elapsed = 599.95
	await get_tree().create_timer(2.9).timeout
	if loop_number != 1 or transitioning or elapsed > 2:
		get_tree().quit(4)
		return
	print("PASS: continuous shell, positive warp Jacobian, deformed aiming, remote operations, CLEAR/RESET Loop 2, timeout/RESET Loop 1")
	get_tree().quit(0)

func _exit_tree() -> void:
	if sound != null:
		sound.stop()
	tick_playback = null

func check_warp() -> bool:
	# Every shell edge has matching samples; shared mapping must keep them closed.
	var edges := {}
	var shell_count := 0
	for child in get_children():
		if child is MeshInstance3D and child.mesh is ArrayMesh:
			shell_count += 1
			var points: PackedVector3Array = child.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
			for i in range(points.size()):
				var row := i / 33
				var col := i % 33
				if row == 0 or row == 32 or col == 0 or col == 32:
					var p := points[i]
					var key := Vector3i(roundi(p.x * 1000), roundi(p.y * 1000), roundi(p.z * 1000))
					edges[key] = int(edges.get(key, 0)) + 1
	if shell_count != 6:
		push_error("Missing shell surface")
		return false
	for count in edges.values():
		if count < 2:
			push_error("Unmatched shell boundary")
			return false
	for strength in [0.0, 0.3, 0.7, 1.0]:
		for x in range(-5, 6):
			for z in range(-5, 6):
				for y in [0.0, 1.65, 3.8]:
					if Warp.jacobian(Vector3(x, y, z), strength).determinant() < 0.35:
						push_error("Warp inverted or collapsed")
						return false
	# Validate actual aim selection at severe deformation, using canonical walk positions.
	for node in interactables:
		player.position = node.global_position + Vector3(0, -1.65, 2.0)
		if str(node.get_meta("kind")) == "door":
			player.position = node.global_position + Vector3(-2.0, -1.65, 0)
		update_camera_position()
		camera.look_at(target_position(node))
		if pick_target() != node:
			push_error("Warped target cannot be aimed at")
			return false
	return true

func capture_stages() -> void:
	var capture_dir := OS.get_environment("ROOM_CAPTURE_DIR")
	if capture_dir.is_empty():
		capture_dir = ProjectSettings.globalize_path("user://previews")
	DirAccess.make_dir_recursive_absolute(capture_dir)
	for stage in range(4):
		preview_stage = stage
		elapsed = [0.0, 200.0, 400.0, 570.0][stage]
		player.rotation.y = -0.16
		camera.rotation.x = -0.06
		update_fold()
		update_camera_position()
		await get_tree().create_timer(0.5).timeout
		await RenderingServer.frame_post_draw
		var result := get_viewport().get_texture().get_image().save_png(capture_dir.path_join("room-stage-%d.png" % stage))
		if result != OK:
			push_error("Screenshot could not be saved")
			get_tree().quit(7)
			return
	print("CAPTURED: four rendered stages")
	get_tree().quit()

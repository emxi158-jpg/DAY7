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

func block(parent: Node3D, pos: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.85
	mesh.material_override = mat
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
	block(self, Vector3(0, -0.15, 0), Vector3(10, 0.3, 10), Color("333639"))
	for x in range(-5, 6):
		block(self, Vector3(x, 0.005, 0), Vector3(0.018, 0.01, 10), Color("161a1c"))
	for z in range(-5, 6):
		block(self, Vector3(0, 0.005, z), Vector3(10, 0.01, 0.018), Color("161a1c"))
	back_wall = region(Vector3(0, 0, -5))
	left_wall = region(Vector3(-5, 0, 0))
	right_wall = region(Vector3(5, 0, 0))
	ceiling = region(Vector3(0, 3.8, 0))
	block(back_wall, Vector3(0, 1.9, 0), Vector3(10.6, 3.8, 0.4), Color("625f52"))
	block(left_wall, Vector3(0, 1.9, 0), Vector3(0.4, 3.8, 10.6), Color("4a504d"))
	block(right_wall, Vector3(0, 1.9, 0), Vector3(0.4, 3.8, 10.6), Color("4a504d"))
	block(ceiling, Vector3.ZERO, Vector3(10.6, 0.3, 10.6), Color("373c39"))
	block(self, Vector3(0, 1.9, 5), Vector3(10.6, 3.8, 0.4), Color("4a504d"))
	# Clock and cabinet share the rear wall so remote changes remain visible.
	var clock := target(back_wall, Vector3(-1.5, 2.65, 0.3), "clock", 0.7)
	var face := MeshInstance3D.new()
	var disc := CylinderMesh.new()
	disc.top_radius = 0.52
	disc.bottom_radius = 0.52
	disc.height = 0.09
	face.mesh = disc
	face.rotation.x = PI / 2
	var face_mat := StandardMaterial3D.new()
	face_mat.albedo_color = Color("d8cba6")
	face.material_override = face_mat
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
	for pos in [Vector3(-1.5, 3.1, -3.6), Vector3(1, 3.1, 0)]:
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
	camera.fov = 75
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
	sound.play()
	tick_playback = sound.get_stream_playback()
	reset_room()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if "--smoke-test" in OS.get_cmdline_user_args():
		call_deferred("smoke_test")

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
			KEY_F: fast = not fast
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
	elapsed = minf(elapsed + delta * (60.0 if fast else 1.0), LIMIT)
	update_fold()
	focused = pick_target()
	var remaining := int(ceil(LIMIT - elapsed))
	timer_label.text = "剩余 %02d:%02d\n%s" % [remaining / 60, remaining % 60, "已解锁 · E 穿过出口" if unlocked else "LOCKED"]
	var prompt := "靠近并对准道具"
	if focused != null:
		var names := {"clock": "挂钟 · E 转动", "cabinet": "储物柜 · E 调节", "door": "出口 · E 进入"}
		prompt = names[str(focused.get_meta("kind"))]
	hud.text = "LOOP %d   /   操作错位\nWASD 移动 · 鼠标观察 · E 操作 · Esc 释放鼠标\nF 加速折叠（%s） · R 重试\n\n%s" % [loop_number, "60倍" if fast else "正常", prompt]
	if elapsed >= LIMIT:
		finish(false)

func pick_target() -> Node3D:
	var best: Node3D = null
	var best_alignment := 0.96
	var forward := -camera.global_basis.z
	for node in interactables:
		var offset := node.global_position - camera.global_position
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
	var t := pow(elapsed / LIMIT, 1.5)
	back_wall.rotation.z = t * 0.21
	back_wall.rotation.x = t * -0.13
	left_wall.rotation.z = t * -0.29
	left_wall.rotation.y = t * 0.10
	right_wall.rotation.z = t * 0.26
	right_wall.rotation.y = t * -0.14
	ceiling.position.y = 3.8 - t * 0.65
	ceiling.rotation.z = t * -0.15
	ceiling.rotation.x = t * 0.09

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
	focused = null
	update_fold()

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
		camera.look_at(node.global_position)
		if pick_target() != node:
			push_error("Unreachable interaction target: " + str(node.get_meta("kind")))
			get_tree().quit(5)
			return
	reset_room()
	elapsed = 500.0
	update_fold()
	if absf(left_wall.rotation.z) < 0.1 or ceiling.position.y >= 3.5:
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
	print("PASS: remote operations, unlock, CLEAR/RESET Loop 2, timeout/RESET Loop 1")
	get_tree().quit(0)

func _exit_tree() -> void:
	if sound != null:
		sound.stop()
	tick_playback = null

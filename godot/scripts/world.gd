extends Node3D

const AssetScript = preload("res://scripts/asset.gd")
const PlayerScript = preload("res://scripts/player.gd")
const SpaceScript = preload("res://scripts/infinite_space.gd")
var current_loop = 1
var gateway_target = "locker_mirror"
var actors = {}
var player
var infinite_space
var enlarged_clock
var status: Label
var message: Label
var ui_font: FontVariation
var loading_ok = false
var clock_panel_open = false
var clock_panel: PanelContainer
var clock_selector: OptionButton
var clock_value: SpinBox
var edited_clock

func _ready() -> void:
	ui_font = FontVariation.new()
	ui_font.base_font = load("res://assets/fonts/NotoSansSC.ttf")
	ui_font.variation_opentype = {"wght":500}
	var room = load("res://room_decor.scn").instantiate()
	add_child(room)
	player = CharacterBody3D.new()
	player.set_script(PlayerScript)
	player.world = self
	add_child(player)
	reset_player()
	var layout = JSON.parse_string(FileAccess.get_file_as_string("res://assets/layout.json"))
	for kind in ["clock","locker","sink","exit","pointer","board"]:
		var actor = Node3D.new()
		actor.name = kind.capitalize()+"Controller"
		actor.set_script(AssetScript)
		add_child(actor)
		var model = load("res://assets/finished/"+kind+".tscn").instantiate()
		actor.add_child(model)
		var p = layout[kind].position_godot
		actor.position = Vector3(p[0],p[1],p[2])
		actor.rotation.y = layout[kind].yaw_godot
		if kind == "clock":
			actor.position = Vector3(.10,2.12,-2.78)
			model.scale.z=.60
		if kind == "board":actor.position = Vector3(-1.4,1.96,-2.755)
		if kind == "locker":
			actor.scale = Vector3(.85,.92,.42)
			actor.position.x = 1.48
			actor.position.z = -2.40
		actor.configure(kind,model,self)
		actor.hint.connect(show_message)
		actors[kind] = actor
	actors.pointer.gateway_changed.connect(_gateway_changed)
	actors.exit.exit_opened.connect(_exit_opened)
	actors.locker.mirror_entered.connect(_enter_mirror)
	infinite_space = Node3D.new()
	infinite_space.name = "IndependentInfiniteSpace"
	infinite_space.set_script(SpaceScript)
	add_child(infinite_space)
	infinite_space.position = Vector3(3.95,0,1.20)
	infinite_space.rotation.y = -PI/2
	infinite_space.configure(player)
	infinite_space.set_active(false)
	# Linked resources: the same clock scene and meshes are duplicated at 3.2x scale.
	enlarged_clock = Node3D.new()
	enlarged_clock.name = "Loop4_SameClock_Enlarged"
	enlarged_clock.set_script(AssetScript)
	add_child(enlarged_clock)
	var copy_model = actors.clock.model.duplicate()
	enlarged_clock.add_child(copy_model)
	enlarged_clock.position = Vector3(0,2.1,1.5)
	enlarged_clock.scale = Vector3.ONE*3.2
	enlarged_clock.configure("clock",copy_model,self)
	enlarged_clock.hide()
	_build_ui()
	set_loop(1)
	loading_ok = true
	print("WAITING_ROOM_FULL_READY")

func _build_environment() -> void:
	var we = WorldEnvironment.new()
	var env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.012,0.017,0.018)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.40,0.46,0.43)
	env.ambient_light_energy = 0.45
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	we.environment = env
	add_child(we)
	for spec in [[Vector3(0.39,2.45,-2.52),Color(1.0,0.65,0.32),1.6,3.0],
		[Vector3(-0.65,2.85,-0.12),Color(0.80,0.86,0.79),1.3,5.1],
		[Vector3(3.40,1.6,1.2),Color(0.30,0.55,0.72),0.65,3.1],
		[Vector3(2.90,2.25,-0.8),Color(0.85,0.81,0.65),0.6,2.5]]:
		var light = OmniLight3D.new()
		light.position = spec[0]
		light.light_color = spec[1]
		light.light_energy = spec[2]
		light.omni_range = spec[3]
		light.shadow_enabled = true
		add_child(light)

func _build_ui() -> void:
	var layer = CanvasLayer.new()
	add_child(layer)
	var panel = VBoxContainer.new()
	panel.position = Vector2(22,16)
	layer.add_child(panel)
	status = Label.new()
	panel.add_child(status)
	var help_label = Label.new()
	help_label.text = "WASD 移动 · 鼠标观察 · E 交互 / 选择钟针 · Shift+E 砸坏龙头\n1–4 切换 Loop · G 放下把手 · L 同款挂钟放大 · R 返回等待室 · Esc 释放鼠标"
	panel.add_child(help_label)
	message = Label.new()
	panel.add_child(message)
	for label in [status,help_label,message]:
		label.add_theme_font_override("font",ui_font)
		label.add_theme_font_size_override("font_size",18)
		label.add_theme_color_override("font_color",Color(0.88,0.88,0.77))
	var crosshair = Label.new()
	crosshair.text = "+"
	crosshair.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	crosshair.position = Vector2(-4,-12)
	layer.add_child(crosshair)
	clock_panel = PanelContainer.new()
	clock_panel.name = "ClockHandSelection"
	clock_panel.position = Vector2(700,365)
	clock_panel.custom_minimum_size = Vector2(420,210)
	layer.add_child(clock_panel)
	var clock_box = VBoxContainer.new()
	clock_box.add_theme_constant_override("separation",12)
	clock_panel.add_child(clock_box)
	var title = Label.new()
	title.text = "调整挂钟"
	clock_box.add_child(title)
	clock_selector = OptionButton.new()
	clock_selector.add_item("时针 · 小时")
	clock_selector.add_item("分针 · 分钟")
	clock_selector.item_selected.connect(_clock_hand_selected)
	clock_box.add_child(clock_selector)
	clock_value = SpinBox.new()
	clock_value.step = 1
	clock_value.value_changed.connect(_clock_value_changed)
	clock_box.add_child(clock_value)
	var close_button = Button.new()
	close_button.text = "完成"
	close_button.pressed.connect(close_clock_panel)
	clock_box.add_child(close_button)
	for control in [title,clock_selector,clock_value,close_button]:
		control.add_theme_font_override("font",ui_font)
		control.add_theme_font_size_override("font_size",24)
	clock_panel.hide()

func open_clock_panel(actor) -> void:
	edited_clock = actor
	clock_panel_open = true
	clock_panel.show()
	_clock_hand_selected(clock_selector.selected)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func close_clock_panel() -> void:
	clock_panel_open = false
	clock_panel.hide()
	if DisplayServer.get_name() != "headless":Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _clock_hand_selected(index: int) -> void:
	if not edited_clock:return
	clock_value.set_block_signals(true)
	clock_value.max_value = 23 if index == 0 else 59
	clock_value.set_value_no_signal(edited_clock.hour_value if index == 0 else edited_clock.minute_value)
	clock_value.set_block_signals(false)

func _clock_value_changed(value: float) -> void:
	if not edited_clock:return
	edited_clock.set_time(int(value) if clock_selector.selected == 0 else edited_clock.hour_value, int(value) if clock_selector.selected == 1 else edited_clock.minute_value)

func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo: return
	if clock_panel_open:
		if event.keycode == KEY_ESCAPE:close_clock_panel()
		return
	match event.keycode:
		KEY_1: set_loop(1)
		KEY_2: set_loop(2)
		KEY_3: set_loop(3)
		KEY_4: set_loop(4)
		KEY_R: reset_player()
		KEY_G: actors.locker.drop_handle()
		KEY_L:
			if current_loop == 4: enlarged_clock.visible = not enlarged_clock.visible

func set_loop(index: int) -> void:
	current_loop = clampi(index,1,4)
	actors.exit.is_locked = current_loop != 2
	if current_loop != 3:
		actors.locker.restore_handle()
		actors.sink.restore_faucet()
	if current_loop != 4: actors.board.set_note_state(0)
	if current_loop != 4: enlarged_clock.hide()
	if current_loop != 2:
		actors.exit.set_exit_open(false,true)
		infinite_space.set_active(false)
	_refresh_gateways()
	show_message("Loop %d：测试对应资产。" % current_loop)
	_update_status()

func _gateway_changed(target: String) -> void:
	gateway_target = target
	_refresh_gateways()
	_update_status()

func _refresh_gateways() -> void:
	actors.locker.set_gateway_active(current_loop == 2 and gateway_target == "locker_mirror")
	actors.exit.set_gateway_active(current_loop == 2 and gateway_target == "exit_door")
	if infinite_space:
		infinite_space.set_active(current_loop == 2 and gateway_target == "exit_door" and actors.exit.is_open)

func _exit_opened(value: bool) -> void:
	if infinite_space: infinite_space.set_active(value and current_loop == 2 and gateway_target == "exit_door")

func _enter_mirror() -> void:
	if current_loop != 2 or gateway_target != "locker_mirror": return
	infinite_space.set_active(true)
	player.global_position = infinite_space.to_global(Vector3(0,0.06,-0.45))
	player.rotation.y = infinite_space.rotation.y
	show_message("已穿过柜内镜面。R 返回等待室。")

func reset_player() -> void:
	if player:
		player.position = Vector3(-1.85,0.08,3.25)
		player.rotation.y = -0.37
		player.velocity = Vector3.ZERO
		if player.camera: player.camera.rotation.x = -0.06

func show_message(text: String) -> void:
	if message: message.text = text

func _update_status() -> void:
	if status: status.text = "第七日 · 等待室 | Loop %d | 当前通道：%s" % [current_loop,gateway_target]

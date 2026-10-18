extends Node3D

signal hint(message: String)
signal gateway_changed(target: String)
signal exit_opened(open: bool)
signal mirror_entered

var kind = ""
var world
var model: Node3D
var parts = {}
var is_open = false
var is_locked = true
var damaged = false
var water_on = false
var handle_detached = false
var holding_handle = false
var hour_value = 10
var minute_value = 56
var target_index = 0
var targets = ["locker_mirror", "exit_door", "off"]
var note_states = ["17:3", "17:30", "18:40"]
var note_index = 0
var mirror_block: CollisionShape3D
var exit_block: CollisionShape3D
var water_particles: CPUParticles3D
var water_jet: MeshInstance3D
var note_label: Label3D
var handle_rigid: RigidBody3D
var original_handle_parent: Node3D
var original_handle_transform: Transform3D
var hand_socket
var motion: Tween
var faucet_rest_rotation = Vector3.ZERO

func part(name_text: String) -> Node3D:
	if parts.has(name_text): return parts[name_text]
	var node = model.find_child(name_text, true, false)
	assert(node != null, "Missing named component: " + name_text)
	parts[name_text] = node
	return node

func configure(asset_kind: String, asset_model: Node3D, host: Node3D) -> void:
	kind = asset_kind
	model = asset_model
	world = host
	match kind:
		"clock":
			part("Clock_HourHand"); part("Clock_MinuteHand"); part("Clock_Pivot")
			area(self, Vector3(0,0,0.08), Vector3(0.60,0.60,0.16), "clock")
			set_time(10,8)
		"locker":
			for name_text in ["Locker_Body","Locker_BackPanel","Locker_MirrorFrame","Locker_TopShelf"]:
				mesh_collision(part(name_text), false)
			mesh_collision(part("Locker_Door"), true)
			area(self, Vector3(0,1.2,0.86), Vector3(1.22,2.32,0.14), "locker_door")
			area(part("Locker_Handle"), Vector3.ZERO, Vector3(0.19,0.19,0.19), "locker_handle")
			original_handle_parent = part("Locker_Handle").get_parent()
			original_handle_transform = part("Locker_Handle").transform
			mirror_block = box_body(self, Vector3(0,1.135,-0.776), Vector3(0.882,2.09,0.018))
			var trigger = area(self, Vector3(0,1.10,-0.84), Vector3(0.82,2.08,0.20), "mirror")
			trigger.collision_mask = 1
			trigger.body_entered.connect(_mirror_body_entered)
		"sink":
			part("Faucet_Broken").visible = false
			part("Faucet_Normal").visible = true
			faucet_rest_rotation = part("Faucet_Handle").rotation
			mesh_collision(part("Sink_Basin"), false)
			mesh_collision(part("Sink_Pedestal"), false)
			area(self, Vector3(0,0.96,0.25), Vector3(0.72,0.40,0.58), "faucet")
			_build_water()
		"exit":
			mesh_collision(part("ExitDoor_Leaf"), true)
			for node in model.find_children("*jamb*", "MeshInstance3D", true, false): mesh_collision(node,false)
			for node in model.find_children("*header*", "MeshInstance3D", true, false): mesh_collision(node,false)
			area(self,Vector3(0,1.2,0.12),Vector3(1.2,2.4,0.20),"exit_door")
			exit_block = box_body(self,Vector3(0,1.15,-0.12),Vector3(1.15,2.30,0.04))
		"pointer":
			part("Pointer_Arrow")
			area(self,Vector3(0,1.38,0.16),Vector3(0.43,0.53,0.20),"pointer")
			select_target(0)
		"board":
			part("KeyNote_Text").hide()
			var note = part("KeyNote_Assembly")
			note_label = Label3D.new()
			note_label.name = "KeyNote_RuntimeText"
			var note_font = FontVariation.new()
			note_font.base_font = load("res://assets/fonts/Kalam-Regular.ttf")
			note_font.variation_opentype = {"wght":600}
			note_label.font = note_font
			note_label.font_size = 46
			note_label.pixel_size = 0.0008
			note_label.modulate = Color(0.05,0.04,0.02)
			note_label.no_depth_test = false
			note_label.outline_size = 0
			note_label.shaded = true
			note_label.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			note.add_child(note_label)
			note_label.position = Vector3(0,-0.005,0.031)
			area(note,Vector3(0,0,0.07),Vector3(0.20,0.16,0.10),"note")
			set_note_state(0)

func area(parent_node: Node3D, pos: Vector3, size: Vector3, action: String) -> Area3D:
	var node = Area3D.new()
	node.name = "Interact_" + action
	node.collision_layer = 2
	node.collision_mask = 0
	node.set_meta("controller",self)
	node.set_meta("action",action)
	parent_node.add_child(node)
	node.position = pos
	var shape_node = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = size
	shape_node.shape = shape
	node.add_child(shape_node)
	return node

func box_body(parent_node: Node3D, pos: Vector3, size: Vector3) -> CollisionShape3D:
	var body = StaticBody3D.new()
	parent_node.add_child(body)
	body.position = pos
	var cs = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = size
	cs.shape = shape
	body.add_child(cs)
	return cs

func mesh_collision(node: Node3D, moving: bool) -> void:
	if not node is MeshInstance3D: return
	var body: PhysicsBody3D = AnimatableBody3D.new() if moving else StaticBody3D.new()
	if moving: body.sync_to_physics = false
	node.add_child(body)
	var cs = CollisionShape3D.new()
	if moving:
		var box = BoxShape3D.new()
		box.size = node.mesh.get_aabb().size
		cs.shape = box
		cs.position = node.mesh.get_aabb().get_center()
	else:
		cs.shape = node.mesh.create_trimesh_shape()
	body.add_child(cs)

func interact(action: String, alternate: bool = false) -> void:
	match action:
		"clock":
			world.open_clock_panel(self)
		"locker_door": set_locker_open(not is_open)
		"locker_handle":
			if world.current_loop == 3:
				if not handle_detached: detach_handle()
				elif not holding_handle: pickup_handle(world.player.hand_socket)
			else: set_locker_open(not is_open)
		"mirror":
			if world.current_loop == 2 and world.gateway_target == "locker_mirror" and is_open: mirror_entered.emit()
		"faucet":
			if alternate and world.current_loop == 3: break_faucet()
			else: set_water(not water_on)
		"exit_door":
			if is_locked: hint.emit("门已上锁。Loop 2 可解锁并测试通道。")
			else: set_exit_open(not is_open)
		"pointer": select_target((target_index+1)%targets.size())
		"note":
			if world.current_loop == 4: set_note_state((note_index+1)%3)
			else: hint.emit("便签：17:3")

func set_time(hours: int, minutes: int) -> void:
	hour_value = posmod(hours + floori(float(minutes)/60.0),24)
	minute_value = posmod(minutes,60)
	part("Clock_HourHand").rotation.z = -TAU * (float(hour_value%12)+float(minute_value)/60.0)/12.0
	part("Clock_MinuteHand").rotation.z = -TAU * float(minute_value)/60.0

func set_locker_open(value: bool, immediate: bool = false) -> void:
	is_open = value
	_rotate(part("Locker_Door"),"rotation:y",deg_to_rad(-105.0) if value else 0.0,immediate)

func set_exit_open(value: bool, immediate: bool = false) -> void:
	is_open = value
	_rotate(part("ExitDoor_Leaf"),"rotation:y",deg_to_rad(105.0) if value else 0.0,immediate)
	exit_opened.emit(value)

func _process(_delta: float) -> void:
	if kind != "exit": return
	var first = model.find_child("ExitDoor_CloserArmA",true,false)
	var second = model.find_child("ExitDoor_CloserArmB",true,false)
	if first == null or second == null: return
	var fixed = Vector3(0.45,2.42,0)
	var hinge = Vector3(0.553,0.03,0.032)
	var rest = Vector3(0.15,2.42,0.14)
	var end = hinge + Basis(Vector3.UP,part("ExitDoor_Leaf").rotation.y)*(rest-hinge)
	var d = end-fixed
	var length = maxf(0.0001,Vector2(d.x,d.z).length())
	var height = sqrt(maxf(0,0.09-length*length/4.0))
	var mid = (fixed+end)/2.0 + Vector3(-d.z,0,d.x)/length*height
	_set_closer_link(first,fixed,mid)
	_set_closer_link(second,mid,end)

func _set_closer_link(node: Node3D, a: Vector3, b: Vector3) -> void:
	var d = b-a
	node.position = a
	node.quaternion = Quaternion(Vector3.UP,d.normalized())
	node.scale = Vector3(1,d.length(),1)

func _rotate(node: Node3D, property_path: String, value: float, immediate: bool) -> void:
	if motion and motion.is_valid(): motion.kill()
	if immediate: node.set_indexed(property_path,value)
	else:
		motion = create_tween()
		motion.tween_property(node,property_path,value,0.65).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func detach_handle() -> void:
	if handle_detached: return
	handle_detached = true
	var handle = part("Locker_Handle")
	var old_transform = handle.global_transform
	handle_rigid = RigidBody3D.new()
	handle_rigid.name = "Locker_DetachedHandle_Physics"
	handle_rigid.mass = 0.35
	world.add_child(handle_rigid)
	handle_rigid.global_transform = old_transform
	handle.reparent(handle_rigid,false)
	handle.transform = Transform3D.IDENTITY
	var cs = CollisionShape3D.new()
	var shape = SphereShape3D.new()
	shape.radius = 0.065
	cs.shape = shape
	handle_rigid.add_child(cs)
	handle_rigid.apply_impulse(Vector3(0.12,0.03,0.13))
	hint.emit("把手脱落了。对准它按 E 拿起，G 放下。")

func pickup_handle(socket: Node3D) -> void:
	if not handle_detached: return
	var handle = part("Locker_Handle")
	handle.reparent(socket,false)
	handle.transform = Transform3D.IDENTITY
	holding_handle = true
	hand_socket = socket
	if is_instance_valid(handle_rigid): handle_rigid.queue_free()
	hint.emit("已拿起柜门把手。按 G 放下。")

func drop_handle() -> void:
	if not holding_handle: return
	var handle = part("Locker_Handle")
	var t = handle.global_transform
	holding_handle = false
	handle_rigid = RigidBody3D.new()
	handle_rigid.mass = 0.35
	world.add_child(handle_rigid)
	handle_rigid.global_transform = t
	handle.reparent(handle_rigid,false)
	handle.transform = Transform3D.IDENTITY
	var cs = CollisionShape3D.new()
	var shape = SphereShape3D.new()
	shape.radius = 0.065
	cs.shape = shape
	handle_rigid.add_child(cs)

func restore_handle() -> void:
	if not handle_detached: return
	var handle = part("Locker_Handle")
	handle.reparent(original_handle_parent,false)
	handle.transform = original_handle_transform
	handle_detached = false
	holding_handle = false
	if is_instance_valid(handle_rigid): handle_rigid.queue_free()

func _build_water() -> void:
	var anchor = part("Faucet_WaterAnchor")
	water_particles = CPUParticles3D.new()
	water_particles.name = "Godot_WaterParticles"
	water_particles.amount = 44
	water_particles.lifetime = 0.30
	water_particles.direction = Vector3.DOWN
	water_particles.spread = 2.5
	water_particles.initial_velocity_min = 0.6
	water_particles.initial_velocity_max = 1.0
	water_particles.gravity = Vector3(0,-9.8,0)
	water_particles.scale_amount_min = 0.0015
	water_particles.scale_amount_max = 0.003
	var sphere = SphereMesh.new()
	sphere.radius = 1
	sphere.height = 2
	water_particles.mesh = sphere
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.30,0.57,0.67,0.6)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.roughness = 0.12
	water_particles.material_override = mat
	anchor.add_child(water_particles)
	water_particles.emitting = false
	water_jet = MeshInstance3D.new()
	water_jet.name = "Godot_WaterJet"
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = 0.003
	cylinder.bottom_radius = 0.004
	cylinder.height = 0.23
	water_jet.mesh = cylinder
	water_jet.material_override = mat
	anchor.add_child(water_jet)
	water_jet.position.y = -0.115
	water_jet.hide()

func set_water(value: bool) -> void:
	water_on = value and not damaged
	water_particles.emitting = water_on
	water_jet.visible = water_on
	part("Faucet_Handle").rotation = faucet_rest_rotation + Vector3(0,0,deg_to_rad(-25.0) if water_on else 0.0)

func break_faucet() -> void:
	set_water(false)
	damaged = true
	part("Faucet_Normal").hide()
	part("Faucet_Broken").show()
	hint.emit("水龙头已损坏；洗手池本体和排水管保持完整。")

func restore_faucet() -> void:
	damaged = false
	part("Faucet_Normal").show()
	part("Faucet_Broken").hide()
	set_water(false)

func select_target(index: int) -> void:
	target_index = posmod(index,targets.size())
	part("Pointer_Arrow").rotation.z = -float(target_index)*PI/2.0
	gateway_changed.emit(targets[target_index])

func set_gateway_active(value: bool) -> void:
	if mirror_block: mirror_block.set_deferred("disabled",value)
	if exit_block: exit_block.set_deferred("disabled",value)

func set_note_state(index: int) -> void:
	note_index = clampi(index,0,2)
	note_label.text = note_states[note_index]
	hint.emit("便签：" + note_states[note_index])

func _mirror_body_entered(body: Node3D) -> void:
	if body == world.player and world.current_loop == 2 and world.gateway_target == "locker_mirror" and is_open:
		mirror_entered.emit()

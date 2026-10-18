extends Node3D

var modules = []
var module_scene: PackedScene
var player: CharacterBody3D
var active = false
var last_base = -999

func configure(actor: CharacterBody3D) -> void:
	player = actor
	module_scene = load("res://assets/models/module.glb")
	for i in range(7):
		var node = module_scene.instantiate()
		node.name = "RepeatedRoom_%02d" % i
		add_child(node)
		modules.append(node)
		for mesh_node in node.find_children("SpaceModule_*", "MeshInstance3D", true, false):
			if "Floor" in mesh_node.name or "Wall" in mesh_node.name or "Ceiling" in mesh_node.name or "DoorFrame" in mesh_node.name:
				mesh_node.create_trimesh_collision()
		var light = OmniLight3D.new()
		light.position = Vector3(0,2.53,-1.7)
		light.light_color = Color(0.65,0.75,0.69)
		light.light_energy = 0.6
		light.omni_range = 3.1
		node.add_child(light)
	_reposition(0)
	hide()
	set_process(false)

func set_active(value: bool) -> void:
	active = value
	visible = value
	set_process(value)
	for node in modules:
		for cs in node.find_children("*", "CollisionShape3D", true, false): cs.set_deferred("disabled",not value)

func _process(_delta: float) -> void:
	if not active: return
	var local_player = to_local(player.global_position)
	var base = maxi(0,floori(-local_player.z/3.24)-1)
	if base != last_base: _reposition(base)

func _reposition(base: int) -> void:
	last_base = base
	for slot in range(modules.size()):
		var index = base + slot
		var room = modules[slot]
		room.position = Vector3(0,-float(index%8)*0.001,-index*3.24)
		room.rotation.y = deg_to_rad([0.0,4.0,-4.0,3.0][index%4])
		room.scale = Vector3([1.0,0.96,1.06,0.94][index%4],[1.0,1.025,0.98,1.04][index%4],1.0)
		# Floor plates overlap; the central walking strip remains continuous.

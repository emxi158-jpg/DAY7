extends CharacterBody3D

var world
var camera: Camera3D
var hand_socket: Node3D
var speed = 2.5
var mouse_sensitivity = 0.002

func _ready() -> void:
	name = "Player"
	var cs = CollisionShape3D.new()
	var capsule = CapsuleShape3D.new()
	capsule.radius = 0.25
	capsule.height = 1.75
	cs.shape = capsule
	cs.position.y = 0.90
	add_child(cs)
	camera = Camera3D.new()
	camera.position.y = 1.60
	camera.fov = 75
	add_child(camera)
	camera.current = true
	hand_socket = Node3D.new()
	hand_socket.name = "HandSocket"
	camera.add_child(hand_socket)
	hand_socket.position = Vector3(0.25,-0.20,-0.50)
	if DisplayServer.get_name() != "headless": Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
	if world.clock_panel_open:return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x*mouse_sensitivity)
		camera.rotation.x = clampf(camera.rotation.x-event.relative.y*mouse_sensitivity,-1.4,1.4)
	if event is InputEventMouseButton and event.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE: Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		if event.keycode == KEY_E: try_interact(event.shift_pressed)

func _physics_process(delta: float) -> void:
	if world.clock_panel_open:
		velocity = Vector3.ZERO
		return
	if not is_on_floor(): velocity.y -= 9.8*delta
	var x = float(Input.is_physical_key_pressed(KEY_D))-float(Input.is_physical_key_pressed(KEY_A))
	var z = float(Input.is_physical_key_pressed(KEY_S))-float(Input.is_physical_key_pressed(KEY_W))
	var dir = (transform.basis*Vector3(x,0,z)).normalized()
	velocity.x = dir.x*speed
	velocity.z = dir.z*speed
	move_and_slide()
	if global_position.y < -8: world.reset_player()

func try_interact(alternate: bool) -> void:
	var from = camera.global_position
	var to = from-camera.global_transform.basis.z*2.6
	var q = PhysicsRayQueryParameters3D.create(from,to,2)
	q.collide_with_areas = true
	q.collide_with_bodies = false
	var hit = get_world_3d().direct_space_state.intersect_ray(q)
	if hit and hit.collider.has_meta("controller"):
		hit.collider.get_meta("controller").interact(hit.collider.get_meta("action"),alternate)

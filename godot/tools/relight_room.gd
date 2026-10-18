extends SceneTree
## Run after geometry refinement. Lights and wall finishes are edited in Godot.
var room:Node3D
func _initialize()->void:call_deferred("run")

func own_all(node:Node)->void:
	for child in node.get_children():
		child.owner=room
		own_all(child)

func flat(color:Color)->StandardMaterial3D:
	var m=StandardMaterial3D.new()
	m.albedo_color=color
	m.roughness=.9
	return m

func prepare_static_furniture()->void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://assets/geometry/lighting"))
	var count=0
	for n in room.get_node("Architecture/FurnitureAndShell").find_children("*","MeshInstance3D",true,false):
		if not n.is_visible_in_tree():continue
		var title=String(n.name)
		if title.begins_with("Ceiling_back_cornice") or title.begins_with("Ceiling_perimeter"):
			n.material_override=flat(Color(.065,.061,.051))
		if "skirting" in title.to_lower():n.material_override=flat(Color(.043,.049,.043))
		if title.begins_with("Plaster_structural_crack") or title.begins_with("Crack_fine_branch"):n.hide()
		if not (title.begins_with("Sofa_") or title.begins_with("Chair_") or title.begins_with("CoffeeTable_") or title.begins_with("SideCabinet_")):continue
		if not n.mesh is ArrayMesh:continue
		var vertex_count=0
		for surface in range(n.mesh.get_surface_count()):vertex_count+=n.mesh.surface_get_array_len(surface)
		# Retain the original million-vertex cushions and their source materials.
		# Their surrounding sofa shell is a static occluder; cushions receive probes.
		if vertex_count>300000:
			print("RETAIN_HIGH_DETAIL_DYNAMIC ",title," vertices=",vertex_count)
			continue
		var path="res://assets/geometry/lighting/"+title.validate_filename()+".res"
		if ResourceLoader.exists(path):
			n.mesh=load(path)
		else:
			var mesh=n.mesh.duplicate()
			mesh.shadow_mesh=null
			print("UNWRAP_FURNITURE ",title," vertices=",vertex_count)
			if mesh.lightmap_unwrap(n.global_transform,.065)!=OK:
				push_error("Furniture unwrap failed: "+title)
				quit(1)
				return
			assert(ResourceSaver.save(mesh,path,ResourceSaver.FLAG_COMPRESS)==OK)
			n.mesh=load(path)
		n.gi_mode=GeometryInstance3D.GI_MODE_STATIC
		count+=1
	room.set_meta("static_furniture_count",count)
	print("STATIC_FURNITURE_READY ",count)

func ceiling_spot(lights:Node,label:String,pos:Vector3,energy:float)->SpotLight3D:
	var old=lights.get_node_or_null(label)
	if old:old.free()
	var light=SpotLight3D.new()
	light.name=label
	lights.add_child(light)
	light.position=pos
	light.look_at(pos+Vector3.DOWN,Vector3.FORWARD)
	light.light_color=Color(1,.90,.78)
	light.light_energy=energy
	light.light_indirect_energy=1.25
	light.light_size=.25
	light.spot_range=7.5
	light.spot_angle=78
	light.spot_attenuation=1.35
	light.spot_angle_attenuation=.8
	light.shadow_enabled=true
	light.shadow_bias=.025
	light.shadow_normal_bias=.25
	light.light_bake_mode=Light3D.BAKE_STATIC
	return light

func relight()->void:
	var lights=room.get_node("Lighting")
	var ceiling=ceiling_spot(lights,"Fluorescent_Main",Vector3(-.65,2.87,-.12),.85)
	ceiling.light_bake_mode=Light3D.BAKE_DYNAMIC
	ceiling.light_size=.50
	ceiling.shadow_normal_bias=.5
	ceiling_spot(lights,"Fluorescent_Spread_L",Vector3(-1.09,2.87,-.12),.52)
	ceiling_spot(lights,"Fluorescent_Spread_R",Vector3(-.21,2.87,-.12),.52)
	var warm=lights.get_node("ClockSconce_Warm")
	warm.position=Vector3(.23,2.59,-2.54)
	warm.look_at(Vector3(.10,1.85,-2.79))
	warm.light_energy=.80
	warm.light_indirect_energy=1.4
	warm.light_color=Color(1,.78,.57)
	warm.light_size=.08
	warm.spot_angle=76
	warm.spot_angle_attenuation=1.7
	warm.spot_range=3.4
	warm.shadow_bias=.04
	warm.shadow_normal_bias=.7
	warm.light_bake_mode=Light3D.BAKE_DYNAMIC
	var exit_light=lights.get_node("Exit_CoolWindow")
	exit_light.light_energy=.48
	exit_light.light_size=.35
	exit_light.light_color=Color(.66,.76,.87)
	exit_light.spot_angle=60
	exit_light.spot_angle_attenuation=1.3
	exit_light.light_bake_mode=Light3D.BAKE_STATIC
	var exit_sign=lights.get_node("Exit_GreenSign")
	exit_sign.light_energy=.035
	exit_sign.shadow_enabled=false
	exit_sign.light_bake_mode=Light3D.BAKE_STATIC
	var bounce=lights.get_node_or_null("WaterStation_Bounce")
	if bounce:bounce.light_energy=.11
	var wall_bounce=lights.get_node_or_null("WarmWall_ReflectedFill")
	if not wall_bounce:
		wall_bounce=OmniLight3D.new()
		wall_bounce.name="WarmWall_ReflectedFill"
		lights.add_child(wall_bounce)
	wall_bounce.position=Vector3(-1.05,2.18,-2.30)
	wall_bounce.light_color=Color(1,.86,.68)
	wall_bounce.light_energy=.16
	wall_bounce.light_specular=0
	wall_bounce.omni_range=3.8
	wall_bounce.shadow_enabled=false
	wall_bounce.light_bake_mode=Light3D.BAKE_STATIC
	var room_bounce=lights.get_node_or_null("RightRoom_ReflectedFill")
	if not room_bounce:
		room_bounce=OmniLight3D.new()
		room_bounce.name="RightRoom_ReflectedFill"
		lights.add_child(room_bounce)
	room_bounce.position=Vector3(1.8,1.85,-.80)
	room_bounce.light_color=Color(.85,.84,.77)
	room_bounce.light_energy=.10
	room_bounce.light_specular=0
	room_bounce.omni_range=3.7
	room_bounce.shadow_enabled=false
	room_bounce.light_bake_mode=Light3D.BAKE_STATIC
	for side in ["L","R"]:
		var tube=room.get_node("Architecture/CeilingFluorescent/Fluorescent_Tube_"+side)
		tube.material_override=tube.material_override.duplicate()
		tube.material_override.emission=Color(1,.89,.73)
		tube.material_override.emission_energy_multiplier=.85
	var bulb=room.get_node("Architecture/ClockWallLamp/Sconce_VisibleWarmBulb")
	bulb.material_override=bulb.material_override.duplicate()
	bulb.material_override.emission_energy_multiplier=2.8
	var env=room.get_node("IndoorEnvironment").environment.duplicate()
	room.get_node("IndoorEnvironment").environment=env
	env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color=Color(.38,.36,.32)
	env.ambient_light_energy=.07
	env.ambient_light_sky_contribution=0
	env.tonemap_exposure=1.15
	env.ssao_radius=.12
	env.ssao_intensity=.55
	env.ssao_power=1.3
	env.glow_intensity=.10
	env.glow_hdr_threshold=1.8
	var gi=room.get_node("BakedIndirectLight")
	gi.quality=LightmapGI.BAKE_QUALITY_HIGH
	gi.bounces=6
	gi.light_data=LightmapGIData.new()
	print("RELIGHT_READY soft ceiling spread, warm wall key, restrained exit fill")

func fix_clock_lip_shadow()->void:
	var clock=load("res://assets/finished/clock.tscn").instantiate()
	clock.scene_file_path=""
	# Rolled lip stays visible/reflected, but its millimetre shadow must not
	# alias into a serrated band on the dial. The case still casts its shadow.
	for child in clock.get_children():
		child.owner=clock
		if child.name in ["Clock_Frame","Clock_BezelWornEdge","Clock_RecessRing"]:
			child.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var packed=PackedScene.new()
	assert(packed.pack(clock)==OK)
	assert(ResourceSaver.save(packed,"res://assets/finished/clock.tscn")==OK)
	clock.free()

func run()->void:
	room=load("res://room_decor.scn").instantiate()
	root.add_child(room)
	room.scene_file_path=""
	prepare_static_furniture()
	relight()
	fix_clock_lip_shadow()
	load("res://tools/clock_contact.gd").apply(room)
	own_all(room)
	var packed=PackedScene.new()
	assert(packed.pack(room)==OK)
	assert(ResourceSaver.save(packed,"res://room_decor.scn",ResourceSaver.FLAG_COMPRESS)==OK)
	print("RELIT_ROOM_SAVED")
	room.queue_free()
	await process_frame
	quit()

extends SceneTree
const OUT="res://samples/material_study/"
const TEX=OUT+"textures/"
var source:Node3D
var sofa_source_transform:Transform3D

func _initialize()->void:call_deferred("run")

func own_all(scene:Node,node:Node)->void:
	for child in node.get_children():
		child.owner=scene
		own_all(scene,child)

func scanned(asset:String,albedo:String)->StandardMaterial3D:
	var m=StandardMaterial3D.new()
	m.albedo_texture=load(TEX+asset+"_"+albedo+"_2k.jpg")
	m.normal_enabled=true
	m.normal_texture=load(TEX+asset+"_nor_gl_2k.jpg")
	m.normal_scale=.85
	m.roughness_texture=load(TEX+asset+"_rough_2k.jpg")
	m.roughness_texture_channel=BaseMaterial3D.TEXTURE_CHANNEL_RED
	m.roughness=1.0
	m.metallic=0
	m.metallic_specular=.45
	m.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	return m

func box(parent:Node,name_:String,size:Vector3,pos:Vector3,mat:Material)->MeshInstance3D:
	var n=MeshInstance3D.new()
	n.name=name_
	var mesh=BoxMesh.new()
	mesh.size=size
	n.mesh=mesh
	n.position=pos
	n.material_override=mat
	parent.add_child(n)
	return n

func stage(after:bool)->Node3D:
	var scene=Node3D.new()
	scene.name="MaterialStudy_"+("After" if after else "Before")
	root.add_child(scene)
	var sofa_source=source.find_child("Sofa_Assembly",true,false)
	var sofa=sofa_source.duplicate()
	sofa.name="Sofa_ExistingGeometry"
	scene.add_child(sofa)
	sofa.global_transform=sofa_source_transform
	sofa.global_position+=Vector3(.93,0,2.0)
	var leather=scanned("brown_leather","albedo") if after else null
	if after:
		leather.uv1_triplanar=true
		leather.uv1_world_triplanar=true
		leather.uv1_scale=Vector3.ONE*2.5
		leather.roughness=.85
		ResourceSaver.save(leather,OUT+"Leather.tres")
	for n in sofa.find_children("*","MeshInstance3D",true,false):
		n.gi_mode=GeometryInstance3D.GI_MODE_DYNAMIC
		if "Throw" in String(n.name):n.hide()
		elif after and "Legs" not in String(n.name):n.material_override=leather
	var plaster:Material
	var dado:Material
	if after:
		plaster=scanned("white_plaster_02","diff")
		plaster.uv1_triplanar=true
		plaster.uv1_world_triplanar=true
		plaster.uv1_scale=Vector3.ONE
		plaster.albedo_color=Color(.55,.52,.46)
		plaster.normal_scale=1.2
		plaster.metallic_specular=.20
		ResourceSaver.save(plaster,OUT+"Plaster.tres")
		dado=plaster.duplicate()
		dado.albedo_color=Color(.24,.31,.28)
		dado.normal_scale=.55
	else:
		plaster=source.find_child("Wall_LockerPortal_Header",true,false).get_active_material(0)
		for n in source.find_children("*","MeshInstance3D",true,false):
			var m=n.get_active_material(0)
			if m is BaseMaterial3D and m.resource_name=="WaitingRoom_dado":
				dado=m
				break
		if not dado:
			dado=plaster.duplicate()
			dado.albedo_color=Color(.49,.60,.55)
	box(scene,"Wall_Upper",Vector3(4.4,1.72,.12),Vector3(0,1.89,-.76),plaster)
	box(scene,"Wall_Dado",Vector3(4.4,1.03,.12),Vector3(0,.515,-.76),dado)
	var skirting=StandardMaterial3D.new()
	skirting.albedo_color=Color(.035,.040,.035)
	skirting.roughness=.80
	box(scene,"Wall_Skirting",Vector3(4.4,.12,.025),Vector3(0,.06,-.688),skirting)
	var floor=Node3D.new()
	floor.name="SmallFloorPatch"
	scene.add_child(floor)
	var old_floor=source.get_node("Architecture/OldTileFloor")
	for x in range(8):
		for z in range(6):
			var tile=MeshInstance3D.new()
			tile.name="Tile_%d_%d"%[x,z]
			tile.mesh=old_floor.get_child(0).mesh
			floor.add_child(tile)
			tile.position=Vector3(-1.925+x*.55,-.014,-.425+z*.55)
			if after:
				var m=scanned("floor_tiles_08","diff")
				# Crop photographic grout: real bevelled geometry owns the seams.
				m.uv1_scale=Vector3(.174,.174,1)
				m.uv1_offset=Vector3((x%5)/5.0+.013,(z%5)/5.0+.013,0)
				m.normal_scale=.75
				m.roughness=.72
				tile.material_override=m
			else:tile.material_override=old_floor.get_child((x*7+z)%old_floor.get_child_count()).get_active_material(0)
	var grout=StandardMaterial3D.new()
	grout.albedo_color=Color(.075,.068,.055)
	grout.roughness=.95
	box(scene,"Floor_GroutBacking",Vector3(4.4,.10,3.3),Vector3(0,-.053,.95),grout)
	var env=Environment.new()
	env.background_mode=Environment.BG_COLOR
	env.background_color=Color(.035,.040,.045)
	env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color=Color(.5,.5,.5)
	env.ambient_light_energy=.12
	env.ambient_light_sky_contribution=0
	env.tonemap_mode=Environment.TONE_MAPPER_AGX
	env.tonemap_exposure=1.0
	env.ssao_enabled=true
	env.ssao_radius=.16
	env.ssao_intensity=.75
	env.ssr_enabled=true
	var we=WorldEnvironment.new()
	we.name="FixedMaterialInspectionEnvironment"
	we.environment=env
	scene.add_child(we)
	var key=OmniLight3D.new()
	key.name="FixedSoftKey"
	scene.add_child(key)
	key.position=Vector3(-1.1,2.60,1.1)
	key.light_energy=1.8
	key.light_color=Color(1,.93,.84)
	key.omni_range=7
	key.light_size=.55
	key.shadow_enabled=true
	key.shadow_normal_bias=.7
	var fill=OmniLight3D.new()
	fill.name="FixedReadableShadowFill"
	scene.add_child(fill)
	fill.position=Vector3(1.7,1.55,1.2)
	fill.omni_range=6
	fill.light_energy=.35
	fill.light_color=Color(.84,.9,1)
	var rake=OmniLight3D.new()
	rake.name="FixedWallRakingLight"
	scene.add_child(rake)
	rake.position=Vector3(-1.85,2.1,-.32)
	rake.omni_range=4
	rake.light_energy=.25
	rake.light_color=Color(1,.89,.73)
	var probe=ReflectionProbe.new()
	probe.name="LocalSurfaceReflections"
	probe.position=Vector3(0,1.25,.8)
	probe.size=Vector3(4.4,2.8,3.3)
	probe.interior=true
	probe.box_projection=true
	scene.add_child(probe)
	var camera=Camera3D.new()
	camera.name="InspectionCamera"
	scene.add_child(camera)
	camera.current=true
	camera.position=Vector3(-2.6,1.4,3.35)
	camera.look_at(Vector3(0,.85,-.10))
	camera.fov=50
	scene.set_meta("comparison","Identical geometry source, light rig, exposure, cameras; after replaces only sample materials and added seams")
	own_all(scene,scene)
	var packed=PackedScene.new()
	assert(packed.pack(scene)==OK)
	assert(ResourceSaver.save(packed,OUT+("after.tscn" if after else "before.tscn"))==OK)
	return scene

func add_surface_stitches(scene:Node3D)->void:
	var seat=scene.find_child("Sofa_SeatCushions",true,false)
	var helper=StaticBody3D.new()
	helper.collision_layer=1<<20
	helper.collision_mask=0
	scene.add_child(helper)
	helper.global_transform=seat.global_transform
	var cs=CollisionShape3D.new()
	cs.shape=seat.mesh.create_trimesh_shape()
	helper.add_child(cs)
	await physics_frame
	await process_frame
	var space=scene.get_world_3d().direct_space_state
	var st=SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var count=0
	for center in [-.93,0.0,.93]:
		for row in [.426,.432]:
			for k in range(111):
				var x=center-.399+k*.0072
				var points=[]
				for offset in [-.0021,.0021]:
					var query=PhysicsRayQueryParameters3D.create(Vector3(x+offset,row,1.1),Vector3(x+offset,row,-.15))
					query.collision_mask=1<<20
					var hit=space.intersect_ray(query)
					if hit.is_empty():break
					assert(hit.collider==helper,"Only the actual seat surface may receive stitches")
					points.append(hit.position+hit.normal*.00055)
				if points.size()!=2:continue
				var direction=(points[1]-points[0]).normalized()
				var basis_=Basis(Quaternion(Vector3.UP,direction))
				for side in range(5):
					var a=TAU*side/5
					var b=TAU*(side+1)/5
					var na=basis_*Vector3(cos(a),0,sin(a))
					var nb=basis_*Vector3(cos(b),0,sin(b))
					for item in [[points[0]+na*.00042,na],[points[1]+nb*.00042,nb],[points[1]+na*.00042,na],[points[0]+na*.00042,na],[points[0]+nb*.00042,nb],[points[1]+nb*.00042,nb]]:
						st.set_normal(item[1])
						st.add_vertex(item[0])
				count+=1
	helper.free()
	var mesh=st.commit()
	assert(count>400,"缝线必须真实投射到坐垫表面")
	assert(ResourceSaver.save(mesh,OUT+"SeatTopstitch.res",ResourceSaver.FLAG_COMPRESS)==OK)
	var thread=StandardMaterial3D.new()
	thread.albedo_color=Color(.14,.095,.055)
	thread.roughness=.9
	var n=MeshInstance3D.new()
	n.name="Seat_SurfaceProjectedTopstitch"
	n.mesh=load(OUT+"SeatTopstitch.res")
	n.material_override=thread
	n.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	scene.add_child(n)
	scene.set_meta("surface_projected_stitches",count)
	print("SURFACE_STITCHES ",count)
	own_all(scene,scene)
	var packed=PackedScene.new()
	assert(packed.pack(scene)==OK)
	assert(ResourceSaver.save(packed,OUT+"after.tscn")==OK)

func capture(scene:Node3D,label:String)->void:
	var camera=scene.get_node("InspectionCamera")
	var views=[
		["00_区域",Vector3(-2.6,1.4,3.35),Vector3(0,.85,-.10),50.0],
		["01_皮革",Vector3(.60,.96,1.34),Vector3(.10,.67,.03),43.0],
		["02_灰泥",Vector3(-1.75,1.62,.30),Vector3(-1.75,1.62,-.70),43.0],
		["03_地砖",Vector3(1.45,.44,1.70),Vector3(.85,.03,.85),47.0]]
	for v in views:
		camera.position=v[1]
		camera.look_at(v[2])
		camera.fov=v[3]
		for frame in range(65):await process_frame
		await RenderingServer.frame_post_draw
		var image=root.get_texture().get_image()
		assert(image.save_png(OUT+"previews/"+label+"_"+v[0]+".png")==OK)
		print("STUDY_CAPTURE ",label," ",v[0])

func run()->void:
	root.size=Vector2i(1920,1080)
	source=load("res://room_decor.scn").instantiate()
	root.add_child(source)
	sofa_source_transform=source.find_child("Sofa_Assembly",true,false).global_transform
	root.remove_child(source)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT+"previews"))
	for after in [false,true]:
		if not after and "--after-only" in OS.get_cmdline_user_args():continue
		var sample=stage(after)
		if after:await add_surface_stitches(sample)
		await capture(sample,"after" if after else "before")
		sample.queue_free()
		await process_frame
	source.free()
	await process_frame
	print("MATERIAL_STUDY_CAPTURED")
	quit()

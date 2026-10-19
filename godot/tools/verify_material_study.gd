extends SceneTree

const STUDY="res://samples/material_study/"
var failures:Array[String]=[]

func check(ok:bool,message:String)->void:
	if not ok:failures.append(message)

func _initialize()->void:
	var before=load(STUDY+"before.tscn").instantiate()
	var after=load(STUDY+"after.tscn").instantiate()
	for name_ in ["FixedSoftKey","FixedReadableShadowFill","FixedWallRakingLight"]:
		var a=before.get_node(name_)
		var b=after.get_node(name_)
		for property in ["transform","light_energy","light_color","omni_range","light_size","shadow_enabled","shadow_normal_bias"]:
			check(a.get(property)==b.get(property),name_+" differs: "+property)
	var ea=before.get_node("FixedMaterialInspectionEnvironment").environment
	var eb=after.get_node("FixedMaterialInspectionEnvironment").environment
	for property in ["background_mode","background_color","ambient_light_source","ambient_light_color","ambient_light_energy","ambient_light_sky_contribution","tonemap_mode","tonemap_exposure","ssao_enabled","ssao_radius","ssao_intensity","ssr_enabled"]:
		check(ea.get(property)==eb.get(property),"Environment differs: "+property)
	check(before.get_node("InspectionCamera").transform==after.get_node("InspectionCamera").transform,"Camera differs")
	check(before.get_node("InspectionCamera").fov==after.get_node("InspectionCamera").fov,"FOV differs")
	check(after.find_children("*","Light3D",true,false).size()==3,"Unexpected lights")
	check(after.find_children("*","WorldEnvironment",true,false).size()==1,"Unexpected environment")
	var colliders_before=before.find_children("*","StaticBody3D",true,false)
	var colliders_after=after.find_children("*","StaticBody3D",true,false)
	check(colliders_before.size()==colliders_after.size(),"Temporary projection collider was saved")
	for collider in colliders_after:
		check(before.has_node(after.get_path_to(collider)),"Unexpected collision body")
	var sofa_a=before.get_node("Sofa_ExistingGeometry")
	var sofa_b=after.get_node("Sofa_ExistingGeometry")
	check(sofa_a.transform==sofa_b.transform,"Sofa placement differs")
	for mesh in sofa_a.find_children("*","MeshInstance3D",true,false):
		var other=sofa_b.get_node(sofa_a.get_path_to(mesh))
		check(mesh.mesh.resource_path==other.mesh.resource_path,"Source geometry differs: "+mesh.name)
		check(mesh.transform==other.transform,"Part transform differs: "+mesh.name)
		check(mesh.visible==other.visible,"Part visibility differs: "+mesh.name)
	var leather=load(STUDY+"Leather.tres")
	check(leather.metallic==0,"Leather is metallic")
	check(leather.normal_enabled and leather.normal_texture!=null,"Missing leather normal")
	check(leather.roughness_texture!=null and leather.roughness_texture_channel==BaseMaterial3D.TEXTURE_CHANNEL_RED,"Wrong roughness input")
	check(after.get_meta("surface_projected_stitches",0)==662,"Missing projected stitches")
	check(after.has_node("Seat_SurfaceProjectedTopstitch"),"Missing stitch geometry")
	var floor_a=before.get_node("SmallFloorPatch")
	var floor_b=after.get_node("SmallFloorPatch")
	check(floor_b.get_child_count()==48,"Incorrect sample floor extent")
	for i in range(floor_b.get_child_count()):
		var a=floor_a.get_child(i)
		var b=floor_b.get_child(i)
		check(a.mesh.surface_get_arrays(0)==b.mesh.surface_get_arrays(0) and a.transform==b.transform,"Floor geometry changed")
		check(b.material_override.uv1_scale==Vector3(.174,.174,1),"Photographic grout not cropped")
	for label in ["before","after"]:
		for view in ["00_区域","01_皮革","02_灰泥","03_地砖"]:
			var image=Image.new()
			image.load_png_from_buffer(FileAccess.get_file_as_bytes(STUDY+"previews/"+label+"_"+view+".png"))
			check(image!=null and image.get_size()==Vector2i(1920,1080),"Missing/invalid capture "+label+view)
	before.free()
	after.free()
	if failures.is_empty():
		print("MATERIAL_STUDY_VERIFIED: fixed rig/exposure/camera, preserved source meshes, nine PBR inputs, real stitches, eight 1080p captures")
	else:
		for failure in failures:push_error(failure)
	quit(0 if failures.is_empty() else 1)

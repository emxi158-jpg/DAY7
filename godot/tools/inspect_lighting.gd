extends SceneTree
func _initialize()->void:call_deferred("run")
func run()->void:
	var room=load("res://room_decor.scn").instantiate()
	root.add_child(room)
	var counts={}
	for n in room.find_children("*","MeshInstance3D",true,false):
		if not n.is_visible_in_tree():continue
		counts[n.gi_mode]=counts.get(n.gi_mode,0)+1
		var title=String(n.name)
		if title in ["Wall_back","Wall_Back","Wall_LockerPortal_Header","Left_upper","Left_lower","Sofa_Body","CoffeeTable_Top","Chair_Body"] or title.begins_with("Wall_stain") or title.begins_with("Wall_mold"):
			var m=n.get_active_material(0)
			print("SURFACE ",title," gi=",n.gi_mode," bounds=",n.global_transform*n.mesh.get_aabb()," mat=",m.resource_name," albedo=",m.albedo_color," tex=",m.albedo_texture.resource_path if m.albedo_texture else "NONE"," normal=",m.normal_scale," uv2=",n.mesh.surface_get_arrays(0)[Mesh.ARRAY_TEX_UV2]!=null)
	print("GI_COUNTS ",counts)
	for n in room.find_children("*","MeshInstance3D",true,false):
		if n.is_visible_in_tree() and n.gi_mode==2 and (n.mesh.get_aabb().size.length()>.75):
			print("DYNAMIC_MAJOR ",n.name," bounds=",n.global_transform*n.mesh.get_aabb()," verts=",n.mesh.surface_get_array_len(0) if n.mesh is ArrayMesh else 0)
	for n in room.find_children("*","Light3D",true,false):
		print("LIGHT ",n.get_path()," pos=",n.global_position," color=",n.light_color," energy=",n.light_energy," indirect=",n.light_indirect_energy," size=",n.light_size," shadow=",n.shadow_enabled," bias=",n.shadow_bias," normal_bias=",n.shadow_normal_bias," bake=",n.light_bake_mode)
	var env=room.get_node("IndoorEnvironment").environment
	for p in ["ambient_light_energy","ambient_light_color","ambient_light_sky_contribution","reflected_light_source","ssao_enabled","ssao_intensity","ssao_power","ssao_radius","ssao_light_affect","tonemap_exposure","tonemap_mode","glow_intensity","glow_hdr_threshold"]:print("ENV ",p,"=",env.get(p))
	for n in room.get_node("Architecture/FurnitureAndShell").get_children():
		var title=String(n.name).to_lower()
		if "stain" in title or "mould" in title or "mold" in title or "plaster" in title or "damp" in title or "trim" in title or "crown" in title or "skirting" in title:print("DETAIL ",n.name," visible=",n.visible)
	quit()

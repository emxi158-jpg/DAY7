extends SceneTree
func _initialize()->void:call_deferred("run")
func run()->void:
	var room=load("res://room_decor.scn").instantiate()
	root.add_child(room)
	for n in room.find_children("*","MeshInstance3D",true,false):
		var title=String(n.name)
		if not n.is_visible_in_tree():continue
		if not (title.begins_with("Sofa_") or title=="Wall_LockerPortal_Header" or title=="Tile_00_00"):continue
		print("ASSET ",n.get_path()," mesh=",n.mesh.resource_path," surfaces=",n.mesh.get_surface_count()," bounds=",n.global_transform*n.mesh.get_aabb())
		for i in range(n.mesh.get_surface_count()):
			var m=n.get_active_material(i)
			if not m is BaseMaterial3D:continue
			print(" MATERIAL ",m.resource_name," color=",m.albedo_color," roughness=",m.roughness," channel=",m.roughness_texture_channel," specular=",m.metallic_specular," normal=",m.normal_enabled," strength=",m.normal_scale," uv_scale=",m.uv1_scale," uv2?=",m.albedo_texture_force_srgb," tri=",m.uv1_triplanar)
			for p in ["albedo_texture","normal_texture","roughness_texture","ao_texture","metallic_texture"]:
				var t=m.get(p)
				print("  ",p,"=",t.resource_path if t else "NONE")
			var arrays=n.mesh.surface_get_arrays(i)
			for slot in [Mesh.ARRAY_TEX_UV,Mesh.ARRAY_TEX_UV2]:
				var uv=arrays[slot]
				if uv==null:continue
				var low=Vector2.ONE*1e9
				var high=-low
				for k in range(0,uv.size(),maxi(1,uv.size()/1000)):
					low=low.min(uv[k]);high=high.max(uv[k])
				print("  UV_SLOT ",slot," count=",uv.size()," min=",low," max=",high)
	quit()

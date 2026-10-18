extends SceneTree
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var room=load("res://room_decor.scn").instantiate()
	root.add_child(room)
	var tile=room.get_node("Architecture/OldTileFloor/Tile_00_00")
	var mat=tile.get_active_material(0)
	print("TILE mesh=",tile.mesh.get_class()," size=",tile.mesh.get_aabb()," roughness=",mat.roughness," channel=",mat.roughness_texture_channel," normal=",mat.normal_scale)
	var arrays=tile.mesh.surface_get_arrays(0)
	var uv=arrays[Mesh.ARRAY_TEX_UV]
	var vertices=arrays[Mesh.ARRAY_VERTEX]
	var selected=[]
	for i in range(vertices.size()):
		if vertices[i].y>.013: selected.append(uv[i])
	print("TOP_UV ",selected)
	for n in room.find_children("*","MeshInstance3D",true,false):
		if n.is_visible_in_tree() and ("Fluorescent" in String(n.name) or "Ceiling_fixture" in String(n.name) or "Fixture_" in String(n.name)):
			print("FIXTURE ",n.name," ",n.global_transform*n.mesh.get_aabb())
	for light in room.get_node("Lighting").get_children():print("LIGHT ",light.name," ",light.position," energy=",light.light_energy," size=",light.light_size)
	for setting in ProjectSettings.get_property_list():
		if "positional_shadow" in String(setting.name):print("SHADOW_SETTING ",setting.name,"=",ProjectSettings.get_setting(setting.name))
	quit()

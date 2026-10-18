extends SceneTree
func _initialize()->void:call_deferred("run")
func run()->void:
	var room=load("res://room_decor.scn").instantiate()
	root.add_child(room)
	assert(room.get_node_or_null("Lighting/Fluorescent_Spread_L")!=null,"长灯管不能只依靠单个集中点光源")
	var moving_key=room.get_node("Lighting/Fluorescent_Main")
	assert(moving_key.light_bake_mode==Light3D.BAKE_DYNAMIC and moving_key.shadow_enabled,"必须保留实时阴影响应柜门、把手与玩家交互")
	var casters=0
	for n in room.get_node("Architecture/FurnitureAndShell").find_children("*","MeshInstance3D",true,false):
		if n.is_visible_in_tree() and n.gi_mode==GeometryInstance3D.GI_MODE_STATIC and (String(n.name).begins_with("Chair_") or String(n.name).begins_with("Sofa_") or String(n.name).begins_with("CoffeeTable_")):casters+=1
	assert(casters>=20,"主要家具必须实际参与静态照明与软阴影烘焙")
	var env=room.get_node("IndoorEnvironment").environment
	assert(env.ambient_light_energy>=.025 and env.ambient_light_sky_contribution==0,"暗部必须有可控的中性环境光")
	var tube=room.get_node("Architecture/CeilingFluorescent/Fluorescent_Tube_L").get_active_material(0)
	assert(tube.emission_energy_multiplier<1.5,"顶灯灯管不能过曝抢占画面")
	print("LIGHTING_STRUCTURE_PASSED static_furniture=",casters)
	quit()

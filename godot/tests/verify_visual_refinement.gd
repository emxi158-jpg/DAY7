extends SceneTree

func _initialize() -> void:call_deferred("run")

func run() -> void:
	var room=load("res://room_decor.scn").instantiate()
	root.add_child(room)
	var tile=room.get_node("Architecture/OldTileFloor/Tile_00_00")
	assert(tile.mesh is ArrayMesh,"地砖需要有真实倒角，不能继续使用直角 BoxMesh")
	var arrays=tile.mesh.surface_get_arrays(0)
	var uv=arrays[Mesh.ARRAY_TEX_UV]
	var normals=arrays[Mesh.ARRAY_NORMAL]
	var uv_min=Vector2.ONE*10
	var uv_max=Vector2.ONE*-10
	var slopes=0
	for i in range(normals.size()):
		if normals[i].y>.99:
			uv_min=uv_min.min(uv[i])
			uv_max=uv_max.max(uv[i])
		elif normals[i].y>.1 and normals[i].y<.95:slopes+=1
	assert(uv_max.x-uv_min.x>.95 and uv_max.y-uv_min.y>.95,"砖面必须使用完整贴图范围")
	assert(slopes>0,"砖边需要真正的斜面")
	var grout=room.get_node("Architecture/Subfloor_Grout")
	assert(absf((grout.transform*grout.mesh.get_aabb()).end.y+.003)<.001,"砖缝下层不能形成几厘米深的黑槽")
	var dispenser=room.get_node("Architecture/WaterDispenser")
	for name_ in ["Dispenser_BlueWaterJug","Dispenser_JugWater","Dispenser_DripTray","Dispenser_Valve_-1","Dispenser_Valve_1"]:
		assert(dispenser.find_child(name_,true,false)!=null,"饮水机缺少构件 "+name_)
	assert(room.get_node("Architecture/AdjacentWardrobe").find_child("Wardrobe_ClothesRail",true,false)!=null)
	var fixture=room.get_node("Architecture/CeilingFluorescent")
	assert(fixture.find_child("Fluorescent_Tube_L",true,false)!=null)
	assert(fixture.find_child("Fluorescent_Tube_R",true,false)!=null)
	for n in room.find_children("*","MeshInstance3D",true,false):
		if String(n.name).begins_with("Ceiling_fixture") or String(n.name).begins_with("Fluorescent_glass_tube"):
			assert(not n.visible,"旧灯具必须停用，避免重叠")
	var clock=load("res://assets/finished/clock.tscn").instantiate()
	root.add_child(clock)
	for part in ["Clock_Frame","Clock_Face","Clock_HourHand","Clock_MinuteHand","Clock_Pivot","Clock_Back","Clock_Glass","Clock_CaseSide","Clock_RecessRing"]:
		assert(clock.find_child(part,true,false)!=null,"挂钟缺少独立构件 "+part)
	var hour=clock.find_child("Clock_HourHand",true,false)
	var minute=clock.find_child("Clock_MinuteHand",true,false)
	var before=minute.transform
	hour.rotate_z(.3)
	assert(minute.transform==before,"时针旋转不能带动分针")
	assert(hour.cast_shadow==GeometryInstance3D.SHADOW_CASTING_SETTING_OFF and minute.cast_shadow==GeometryInstance3D.SHADOW_CASTING_SETTING_OFF,"薄钟针不能在表盘上产生锯齿阴影")
	var dial_image=load("res://assets/materials/refined/clock_dial.png").get_image()
	if dial_image.is_compressed():assert(dial_image.decompress()==OK)
	var dial_color=dial_image.get_pixel(512,512)
	assert(dial_color.r-dial_color.b<.075 and dial_color.g-dial_color.b<.065,"表盘底色必须是米白色，暖色由灯光提供")
	print("VISUAL_REFINEMENT_PASSED full_tile_uv=",uv_max-uv_min," chamfer_vertices=",slopes)
	room.queue_free()
	clock.queue_free()
	await process_frame
	quit()

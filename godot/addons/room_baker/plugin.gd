@tool
extends EditorPlugin

func _enter_tree() -> void:
	if FileAccess.file_exists("res://bake_request.flag"):
		run_bake.call_deferred()

func wait_frames(count: int) -> void:
	for index in range(count):await get_tree().process_frame

func find_bake_button(node: Node) -> Button:
	if node is Button and node.is_visible_in_tree():
		var txt = String(node.text)
		if "Bake Lightmaps" in txt or "烘焙光照" in txt or "烘焙光照贴图" in txt:
			return node
	for child in node.get_children():
		var found = find_bake_button(child)
		if found:return found
	return null

func run_bake() -> void:
	await wait_frames(90)
	while EditorInterface.get_resource_filesystem().is_scanning():
		await get_tree().create_timer(.25).timeout
	EditorInterface.open_scene_from_path("res://room_decor.scn")
	await wait_frames(45)
	var root = EditorInterface.get_edited_scene_root()
	if not root:
		push_error("No edited sample scene")
		get_tree().quit(1)
		return
	var gi = root.get_node("BakedIndirectLight")
	var saved = ResourceSaver.save(gi.light_data,"res://baked/room.lmbake",ResourceSaver.FLAG_CHANGE_PATH)
	assert(saved == OK)
	gi.light_data = ResourceLoader.load("res://baked/room.lmbake","",ResourceLoader.CACHE_MODE_IGNORE)
	EditorInterface.save_scene()
	print("SAMPLE_LIGHTMAP_DATA_PATH ",gi.light_data.resource_path)
	EditorInterface.get_selection().clear()
	EditorInterface.get_selection().add_node(gi)
	EditorInterface.edit_node(gi)
	await wait_frames(30)
	var button = find_bake_button(EditorInterface.get_base_control())
	if not button:
		for child in EditorInterface.get_base_control().find_children("*","Button",true,false):
			if child.is_visible_in_tree() and not child.text.is_empty():print("VISIBLE_BUTTON ",child.text)
		push_error("LightmapGI bake button was not found")
		get_tree().quit(2)
		return
	print("SAMPLE_LIGHTMAP_BAKE_STARTED ",button.text)
	button.pressed.emit()
	await wait_frames(3)
	# Godot may request an image path even when a LightmapGIData resource was saved.
	# Complete that editor action with the sample's explicitly chosen output path.
	for dialog in button.find_children("*","EditorFileDialog",true,false):
		if dialog.visible:
			print("SAMPLE_LIGHTMAP_OUTPUT_SELECTED res://baked/room.lmbake")
			dialog.hide()
			dialog.file_selected.emit("res://baked/room.lmbake")
	await wait_frames(90)
	EditorInterface.save_scene()
	var users = gi.light_data.get_user_count() if gi.light_data else 0
	var report = {"baked_users":users,"passed":users>0,"tool":"Godot 4.6 LightmapGI editor GPU baker"}
	FileAccess.open("res://lightmap_verification.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	print("SAMPLE_LIGHTMAP_BAKE_FINISHED ",JSON.stringify(report))
	DirAccess.remove_absolute(ProjectSettings.globalize_path("res://bake_request.flag"))
	await wait_frames(15)
	get_tree().quit(0 if users>0 else 3)

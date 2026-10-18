extends SceneTree
func _initialize()->void:call_deferred("run")
func run()->void:
	var room=load("res://room_decor.scn").instantiate()
	root.add_child(room)
	room.scene_file_path=""
	load("res://tools/clock_contact.gd").apply(room)
	var packed=PackedScene.new()
	assert(packed.pack(room)==OK)
	assert(ResourceSaver.save(packed,"res://room_decor.scn",ResourceSaver.FLAG_COMPRESS)==OK)
	room.queue_free()
	await process_frame
	quit()

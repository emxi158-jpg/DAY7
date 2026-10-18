extends RefCounted
## Fixed wall-mounted clock: smooth contact occlusion, no PCSS silhouette aliasing.
static func apply(room:Node3D)->void:
	var clock=load("res://assets/finished/clock.tscn").instantiate()
	clock.scene_file_path=""
	for n in clock.find_children("*","MeshInstance3D",true,false):
		n.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		# All meshes in this scene are direct children; retain explicit ownership.
		n.owner=clock
	var packed=PackedScene.new()
	assert(packed.pack(clock)==OK)
	assert(ResourceSaver.save(packed,"res://assets/finished/clock.tscn")==OK)
	clock.free()
	var architecture=room.get_node("Architecture")
	var old=architecture.get_node_or_null("Clock_ContactShadow")
	if old:old.free()
	var shadow=MeshInstance3D.new()
	shadow.name="Clock_ContactShadow"
	architecture.add_child(shadow)
	var mesh=QuadMesh.new()
	mesh.size=Vector2(.70,.70)
	shadow.mesh=mesh
	shadow.position=Vector3(.10,2.105,-2.796)
	shadow.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	shadow.gi_mode=GeometryInstance3D.GI_MODE_DISABLED
	var shader=Shader.new()
	shader.code="shader_type spatial; render_mode unshaded, depth_draw_never, cull_disabled, shadows_disabled; void fragment(){ float r=length((UV-vec2(0.5))*2.0); ALBEDO=vec3(0.008,0.007,0.006); ALPHA=(1.0-smoothstep(0.83,1.0,r))*0.42; }"
	var mat=ShaderMaterial.new()
	mat.shader=shader
	shadow.material_override=mat
	shadow.owner=room

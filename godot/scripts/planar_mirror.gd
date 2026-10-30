extends Node3D
# A clipped off-axis reflection view framed by the actual mirror rectangle.
var surface:MeshInstance3D
var source_camera:Camera3D
var reflection_camera:Camera3D
var viewport:SubViewport
var mirror_size=Vector2(.458,.647)
func configure(mesh:MeshInstance3D,viewer:Camera3D,environment:Environment)->void:
 surface=mesh;source_camera=viewer;process_priority=100
 surface.layers=1<<17
 var face=QuadMesh.new();face.size=mirror_size
 surface.mesh=face;surface.position+=Vector3(0,0,.0046)
 surface.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 surface.gi_mode=GeometryInstance3D.GI_MODE_DISABLED
 viewport=SubViewport.new();viewport.name="MirrorViewport";viewport.size=Vector2i(544,768);viewport.own_world_3d=false;viewport.world_3d=surface.get_world_3d();viewport.use_hdr_2d=true;viewport.msaa_3d=Viewport.MSAA_2X;viewport.positional_shadow_atlas_size=2048
 add_child(viewport)
 reflection_camera=Camera3D.new();reflection_camera.name="ReflectedCamera";viewport.add_child(reflection_camera);reflection_camera.current=true
 reflection_camera.cull_mask=((1<<20)-1) & ~(1<<17)
 var reflected_env=environment.duplicate();reflected_env.tonemap_mode=Environment.TONE_MAPPER_LINEAR;reflected_env.tonemap_exposure=1.;reflected_env.glow_enabled=false;reflected_env.ssr_enabled=false
 reflection_camera.environment=reflected_env
 var material=ShaderMaterial.new();material.shader=load("res://assets/materials/planar_mirror.gdshader");material.set_shader_parameter("reflection_texture",viewport.get_texture());surface.material_override=material
 update_view()
func _process(_delta:float)->void:update_view()
func update_view()->void:
 if not is_instance_valid(source_camera) or not is_instance_valid(surface):return
 var normal=surface.global_basis.z.normalized();var center=surface.global_position
 var distance=(source_camera.global_position-center).dot(normal)
 if distance<.025 or not surface.is_visible_in_tree():viewport.render_target_update_mode=SubViewport.UPDATE_DISABLED;return
 viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS if mirror_on_screen() else SubViewport.UPDATE_DISABLED
 var eye=source_camera.global_position-2.*normal*distance
 var right=-surface.global_basis.x.normalized();var up=surface.global_basis.y.normalized()
 reflection_camera.global_transform=Transform3D(Basis(right,up,-normal),eye)
 var clip=distance+.002;var ratio=clip/distance
 var offset=Vector2((center-eye).dot(right),(center-eye).dot(up))*ratio
 reflection_camera.keep_aspect=Camera3D.KEEP_HEIGHT
 reflection_camera.set_frustum(mirror_size.y*ratio,offset,clip,60.)

func mirror_on_screen()->bool:
 var screen=source_camera.get_viewport().get_visible_rect()
 var bounds=Rect2();var count=0
 for x in [-.5,.5]:
  for y in [-.5,.5]:
   var corner=surface.to_global(Vector3(x*mirror_size.x,y*mirror_size.y,0))
   if source_camera.is_position_behind(corner):continue
   var point=source_camera.unproject_position(corner)
   if count==0:bounds=Rect2(point,Vector2.ZERO)
   else:bounds=bounds.expand(point)
   count+=1
 return count>0 and screen.intersects(bounds.grow(4.))

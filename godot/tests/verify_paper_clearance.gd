extends SceneTree
func _initialize():call_deferred("run")
func run():
 var b=load("res://assets/finished/board.tscn").instantiate();root.add_child(b)
 var cork=b.get_node("BulletinBoard_Assembly/BulletinBoard_Cork")
 var front=(b.global_transform.affine_inverse()*cork.global_transform*cork.mesh.get_aabb()).end.z
 var failures=0
 for k in range(1,7):
  var p=b.get_node("Notice%02d_Paper"%k);var minimum=INF
  for s in range(p.mesh.get_surface_count()):
   var ar=p.mesh.surface_get_arrays(s)
   for v in ar[Mesh.ARRAY_VERTEX]:minimum=minf(minimum,b.to_local(p.to_global(v)).z-front)
  print("PAPER_CLEARANCE ",k," mm=",minimum*1000)
  if minimum<.00015:failures+=1
 b.free();print("PAPER_CONTACT_TEST failures=",failures);quit(1 if failures else 0)

extends SceneTree
## Rebuild only the floor, fluorescent fixture and interactive clock in Godot.
const MAPS="res://assets/materials/refined/"
var room:Node3D

func _initialize() -> void:call_deferred("run")

func material(color:Color,rough:float=.6,metal:float=0.0)->StandardMaterial3D:
	var m=StandardMaterial3D.new()
	m.albedo_color=color
	m.roughness=rough
	m.metallic=metal
	m.metallic_specular=.35
	return m

func add_mesh(parent:Node,name_:String,mesh:Mesh,mat:Material,pos:Vector3=Vector3.ZERO)->MeshInstance3D:
	var n=MeshInstance3D.new()
	n.name=name_
	n.mesh=mesh
	n.material_override=mat
	n.position=pos
	n.gi_mode=GeometryInstance3D.GI_MODE_STATIC
	parent.add_child(n)
	return n

func box(parent:Node,name_:String,size:Vector3,pos:Vector3,mat:Material)->MeshInstance3D:
	var mesh=BoxMesh.new()
	mesh.size=size
	return add_mesh(parent,name_,mesh,mat,pos)

func cylinder(parent:Node,name_:String,radius:float,height:float,pos:Vector3,mat:Material,axis_z:bool=true)->MeshInstance3D:
	var mesh=CylinderMesh.new()
	mesh.top_radius=radius
	mesh.bottom_radius=radius
	mesh.height=height
	mesh.radial_segments=96
	var n=add_mesh(parent,name_,mesh,mat,pos)
	if axis_z:n.rotation.x=PI/2
	return n

func ring(parent:Node,name_:String,inner:float,outer:float,z:float,mat:Material)->MeshInstance3D:
	var mesh=TorusMesh.new()
	mesh.inner_radius=inner
	mesh.outer_radius=outer
	mesh.rings=128
	mesh.ring_segments=16
	var n=add_mesh(parent,name_,mesh,mat,Vector3(0,0,z))
	n.rotation.x=PI/2
	return n

func quad(st:SurfaceTool,points:Array,normal:Vector3,uvs:Array)->void:
	var order=[0,1,2,0,2,3]
	if (points[1]-points[0]).cross(points[2]-points[0]).dot(normal)>0:
		order=[0,3,2,0,2,1]
	for i in order:
		st.set_normal(normal)
		st.set_uv(uvs[i])
		st.add_vertex(points[i])

func tile_mesh()->ArrayMesh:
	var st=SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var half=.273
	var inset=.002
	var top=[Vector3(-half+inset,.014,-half+inset),Vector3(half-inset,.014,-half+inset),Vector3(half-inset,.014,half-inset),Vector3(-half+inset,.014,half-inset)]
	var shoulder=[Vector3(-half,.011,-half),Vector3(half,.011,-half),Vector3(half,.011,half),Vector3(-half,.011,half)]
	var uv=[Vector2(0,0),Vector2(1,0),Vector2(1,1),Vector2(0,1)]
	quad(st,top,Vector3.UP,uv)
	for i in range(4):
		var j=(i+1)%4
		var outward=((top[i]+top[j])/2*Vector3(1,0,1)).normalized()
		quad(st,[top[i],top[j],shoulder[j],shoulder[i]],(outward+Vector3.UP*.67).normalized(),[uv[i],uv[j],uv[j]+Vector2(.003,.003),uv[i]+Vector2(.003,.003)])
		var bottom_i=Vector3(shoulder[i].x,-.014,shoulder[i].z)
		var bottom_j=Vector3(shoulder[j].x,-.014,shoulder[j].z)
		quad(st,[shoulder[i],shoulder[j],bottom_j,bottom_i],outward,[Vector2(0,0),Vector2(1,0),Vector2(1,.05),Vector2(0,.05)])
	st.generate_tangents()
	var mesh=st.commit()
	mesh.lightmap_unwrap(Transform3D.IDENTITY,.055)
	return mesh

func build_floor()->void:
	var floor=room.get_node("Architecture/OldTileFloor")
	var shared=tile_mesh()
	ResourceSaver.save(shared,"res://assets/geometry/RefinedTile.res",ResourceSaver.FLAG_COMPRESS)
	var mats=[]
	for i in range(4):
		var m=material(Color.WHITE,1.0)
		m.albedo_texture=load(MAPS+"tile_%d_albedo.png"%i)
		m.roughness_texture=load(MAPS+"tile_%d_roughness.png"%i)
		m.roughness_texture_channel=BaseMaterial3D.TEXTURE_CHANNEL_GREEN
		m.normal_enabled=true
		m.normal_texture=load(MAPS+"tile_%d_normal.png"%i)
		m.normal_scale=.45
		m.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
		m.metallic_specular=.45
		ResourceSaver.save(m,"res://assets/materials/refined/Tile_%d.tres"%i)
		mats.append(m)
	var grout=room.get_node("Architecture/Subfloor_Grout")
	grout.position.y=-.053
	grout.material_override=material(Color(.095,.087,.071),.94)
	for t in floor.get_children():
		var number=int(String(t.name).get_slice("_",1))*12+int(String(t.name).get_slice("_",2))
		t.mesh=shared
		t.material_override=mats[(number*7+number/12)%4]
		t.set_meta("surface","worn ceramic glaze; full-face UV; 2mm chamfer")
	print("REFINED_FLOOR ",floor.get_child_count())

func build_fixture()->void:
	var architecture=room.get_node("Architecture")
	for n in architecture.find_children("*","MeshInstance3D",true,false):
		var name_=String(n.name)
		if name_.begins_with("Ceiling_fixture") or name_.begins_with("Fluorescent_") or name_.begins_with("Fixture_suspension") or name_=="Fluorescent ceiling light":n.hide()
	var old=architecture.get_node_or_null("CeilingFluorescent")
	if old:old.free()
	var fixture=Node3D.new()
	fixture.name="CeilingFluorescent"
	architecture.add_child(fixture)
	fixture.position=Vector3(-.65,0,-.12)
	var casing=material(Color(.105,.115,.105),.66,.55)
	casing.albedo_texture=load(MAPS+"clock_metal.png")
	casing.albedo_color=Color(.95,1,.94)
	var reflector=material(Color(.57,.55,.46),.49,.18)
	var ceramic=material(Color(.49,.46,.36),.62)
	var screw=material(Color(.12,.13,.12),.46,.8)
	box(fixture,"Fluorescent_MetalTray",Vector3(1.64,.045,.43),Vector3(0,3.015,0),casing)
	box(fixture,"Fluorescent_Reflector",Vector3(1.56,.013,.37),Vector3(0,2.984,0),reflector)
	for side in [-1,1]:
		var flange=box(fixture,"Fluorescent_RolledSide_%d"%side,Vector3(1.64,.07,.018),Vector3(0,2.993,side*.208),casing)
		flange.rotation.x=side*.11
		box(fixture,"Fluorescent_EndCover_%d"%side,Vector3(.025,.093,.43),Vector3(side*.81,2.986,0),casing)
		for z in [-.11,.11]:
			box(fixture,"Fluorescent_CeramicSocket_%d_%d"%[side,int(z*100)],Vector3(.047,.059,.048),Vector3(side*.709,2.961,z),ceramic)
			var end=cylinder(fixture,"Fluorescent_TubeEnd_%d_%d"%[side,int(z*100)],.0188,.039,Vector3(side*.675,2.943,z),screw,false)
			end.rotation.z=PI/2
			var bolt=cylinder(fixture,"Fluorescent_Bolt_%d_%d"%[side,int(z*100)],.006,.004,Vector3(side*.772,2.972,z),screw,false)
			box(bolt,"ScrewSlot",Vector3(.007,.001,.0015),Vector3(0,-.0022,0),casing)
	var tube_mat=material(Color(.84,.85,.75),.35)
	tube_mat.emission_enabled=true
	tube_mat.emission=Color(.92,.94,.83)
	tube_mat.emission_energy_multiplier=4.0
	for side in [-1,1]:
		var tube=cylinder(fixture,"Fluorescent_Tube_"+("L" if side<0 else "R"),.0175,1.315,Vector3(0,2.943,side*.11),tube_mat,false)
		tube.rotation.z=PI/2
	var starter=cylinder(fixture,"Fluorescent_Starter",.013,.032,Vector3(.59,2.956,0),ceramic,false)
	starter.rotation.z=PI/2
	var light=room.get_node("Lighting/Fluorescent_Main")
	light.position=Vector3(-.65,2.84,-.12)
	light.light_size=.13
	light.light_energy=1.10
	light.light_color=Color(.93,.95,.86)
	light.shadow_normal_bias=.65
	var warm=room.get_node("Lighting/ClockSconce_Warm")
	warm.light_energy=.40
	warm.light_size=.085
	var bulb=architecture.get_node("ClockWallLamp/Sconce_VisibleWarmBulb")
	bulb.mesh=bulb.mesh.duplicate()
	bulb.mesh.radius=.014
	bulb.mesh.height=.028
	bulb.position.y=-.097
	bulb.material_override=bulb.material_override.duplicate()
	bulb.material_override.emission_energy_multiplier=5.0
	print("REFINED_FIXTURE ",fixture.get_child_count())

func disk(radius:float)->ArrayMesh:
	var st=SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(128):
		for p in [Vector2.ZERO,Vector2(cos(TAU*(i+1)/128),sin(TAU*(i+1)/128))*radius,Vector2(cos(TAU*i/128),sin(TAU*i/128))*radius]:
			st.set_normal(Vector3.BACK)
			st.set_uv(p/(radius*2)+Vector2.ONE*.5)
			st.add_vertex(Vector3(p.x,p.y,0))
	st.generate_tangents()
	return st.commit()

func hand_mesh(points:PackedVector2Array,thickness:float=.002)->ArrayMesh:
	var st=SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var indices=Geometry2D.triangulate_polygon(points)
	for side in [-1,1]:
		for i in range(0,indices.size(),3):
			var order=[indices[i],indices[i+1],indices[i+2]]
			var a=points[order[0]]
			var b=points[order[1]]
			var c=points[order[2]]
			if (b-a).cross(c-a)*side>0:order.reverse()
			for index in order:
				st.set_normal(Vector3(0,0,side))
				st.set_uv(points[index]*2+Vector2.ONE*.5)
				st.add_vertex(Vector3(points[index].x,points[index].y,side*thickness*.5))
	for i in range(points.size()):
		var a=points[i]
		var b=points[(i+1)%points.size()]
		var n=Vector3(b.y-a.y,a.x-b.x,0).normalized()
		quad(st,[Vector3(a.x,a.y,-thickness*.5),Vector3(b.x,b.y,-thickness*.5),Vector3(b.x,b.y,thickness*.5),Vector3(a.x,a.y,thickness*.5)],n,[Vector2.ZERO,Vector2.RIGHT,Vector2.ONE,Vector2.DOWN])
	st.generate_tangents()
	return st.commit()

func glass_dome()->ArrayMesh:
	var st=SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for r in range(12):
		for i in range(96):
			var pts=[]
			var uvs=[]
			for spec in [Vector2(r,i),Vector2(r+1,i),Vector2(r+1,i+1),Vector2(r,i+1)]:
				var rad=maxf(.00001,spec.x/12*.289)
				var p=Vector2(cos(spec.y/96*TAU),sin(spec.y/96*TAU))*rad
				pts.append(Vector3(p.x,p.y,.010*(1-p.length_squared()/(.289*.289))))
				uvs.append(p/.578+Vector2.ONE*.5)
			quad(st,pts,Vector3.BACK,uvs)
	return st.commit()

func own_all(root_:Node,node:Node)->void:
	for child in node.get_children():
		child.owner=root_
		own_all(root_,child)

func beveled_box(size:Vector3,bevel:float)->ArrayMesh:
	var st=SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rings=[]
	for spec in [Vector2(-size.y/2,bevel),Vector2(-size.y/2+bevel,0),Vector2(size.y/2-bevel,0),Vector2(size.y/2,bevel)]:
		var x=size.x/2-spec.y
		var z=size.z/2-spec.y
		var c=bevel*.70
		rings.append([Vector3(-x+c,spec.x,-z),Vector3(x-c,spec.x,-z),Vector3(x,spec.x,-z+c),Vector3(x,spec.x,z-c),Vector3(x-c,spec.x,z),Vector3(-x+c,spec.x,z),Vector3(-x,spec.x,z-c),Vector3(-x,spec.x,-z+c)])
	for layer in range(3):
		for i in range(8):
			var j=(i+1)%8
			var points=[rings[layer][i],rings[layer][j],rings[layer+1][j],rings[layer+1][i]]
			var n=(points[1]-points[0]).cross(points[2]-points[0]).normalized()
			if n.dot((points[0]+points[2])*.5)<0:n=-n
			quad(st,points,n,[Vector2(i/8.0,layer/3.0),Vector2(j/8.0,layer/3.0),Vector2(j/8.0,(layer+1)/3.0),Vector2(i/8.0,(layer+1)/3.0)])
	for side in [0,3]:
		for i in range(8):
			var a=rings[side][i]
			var b=rings[side][(i+1)%8]
			var center=Vector3(0,a.y,0)
			var pts=[center,a,b]
			var n=Vector3.DOWN if side==0 else Vector3.UP
			if (a-center).cross(b-center).dot(n)>0:pts.reverse()
			for p in pts:
				st.set_normal(n)
				st.set_uv(Vector2(p.x/size.x+.5,p.z/size.z+.5))
				st.add_vertex(p)
	st.generate_tangents()
	var mesh=st.commit()
	mesh.lightmap_unwrap(Transform3D.IDENTITY,.055)
	return mesh

func bevel(parent:Node,name_:String,size:Vector3,pos:Vector3,mat:Material,amount:float=.006)->MeshInstance3D:
	return add_mesh(parent,name_,beveled_box(size,amount),mat,pos)

func lathe(profile:Array,segments:int=80)->ArrayMesh:
	var st=SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for j in range(profile.size()-1):
		var delta=profile[j+1]-profile[j]
		var slope=Vector2(delta.y,-delta.x).normalized()
		for i in range(segments):
			for spec in [Vector2(j,i),Vector2(j+1,i+1),Vector2(j+1,i),Vector2(j,i),Vector2(j,i+1),Vector2(j+1,i+1)]:
				var p=profile[int(spec.x)]
				var angle=spec.y/segments*TAU
				st.set_normal(Vector3(cos(angle)*slope.x,slope.y,sin(angle)*slope.x))
				st.set_uv(Vector2(spec.y/segments,spec.x/(profile.size()-1)))
				st.add_vertex(Vector3(cos(angle)*p.x,p.y,sin(angle)*p.x))
	st.generate_tangents()
	return st.commit()

func build_dispenser()->void:
	var architecture=room.get_node("Architecture")
	var prefixes=["Blue_jug","Bottle_cap","Cup_recess","Dispenser_","Jug_","Lower_service_door","Service_vent","Upper_controls","Water_tap","Water_volume"]
	for n in architecture.find_children("*","MeshInstance3D",true,false):
		for prefix in prefixes:
			if String(n.name).begins_with(prefix):n.hide()
	var old=architecture.get_node_or_null("WaterDispenser")
	if old:old.free()
	var dispenser=Node3D.new()
	dispenser.name="WaterDispenser"
	architecture.add_child(dispenser)
	dispenser.position=Vector3(-3.35,0,-2.22)
	var paint=material(Color.WHITE,.63,.05)
	paint.albedo_texture=load(MAPS+"dispenser_enamel.png")
	paint.roughness_texture=load(MAPS+"dispenser_roughness.png")
	paint.uv1_triplanar=true
	paint.uv1_scale=Vector3(2,2,2)
	var rubber=material(Color(.021,.024,.022),.82)
	var cream=material(Color(.60,.59,.51),.52)
	var cavity=material(Color(.037,.044,.041),.80)
	var chrome=material(Color(.29,.31,.28),.32,.75)
	bevel(dispenser,"Dispenser_Base",Vector3(.37,.055,.37),Vector3(0,.049,0),rubber)
	for x in [-.145,.145]:
		for z in [-.145,.145]:cylinder(dispenser,"Dispenser_Foot_%d_%d"%[int(x*100),int(z*100)],.018,.04,Vector3(x,.022,z),rubber,false)
	bevel(dispenser,"Dispenser_Rear",Vector3(.345,.915,.045),Vector3(0,.512,-.155),paint)
	for side in [-1,1]:bevel(dispenser,"Dispenser_Side_%d"%side,Vector3(.035,.915,.345),Vector3(side*.17,.512,0),paint)
	bevel(dispenser,"Dispenser_ServicePanel",Vector3(.305,.49,.026),Vector3(0,.318,.169),paint)
	bevel(dispenser,"Dispenser_ControlFascia",Vector3(.31,.145,.04),Vector3(0,.892,.169),paint)
	bevel(dispenser,"Dispenser_TopCap",Vector3(.382,.043,.382),Vector3(0,.989,0),paint)
	box(dispenser,"Dispenser_TapRecess",Vector3(.307,.252,.016),Vector3(0,.689,-.090),cavity)
	bevel(dispenser,"Dispenser_DripTray",Vector3(.312,.026,.217),Vector3(0,.565,.085),rubber,.004)
	for i in range(17):box(dispenser,"Dispenser_TrayGrille_%02d"%i,Vector3(.006,.004,.17),Vector3(-.137+i*.017,.580,.085),chrome)
	for side in [-1,1]:
		var x=side*.078
		var valve=cylinder(dispenser,"Dispenser_Valve_%d"%side,.022,.070,Vector3(x,.786,.130),cream)
		bevel(dispenser,"Dispenser_PushLever_%d"%side,Vector3(.034,.012,.067),Vector3(x,.814,.155),material(Color(.065,.15,.21) if side<0 else Color(.30,.08,.04),.58),.003)
		cylinder(dispenser,"Dispenser_DownSpout_%d"%side,.012,.040,Vector3(x,.756,.167),cream,false)
		cylinder(dispenser,"Dispenser_NozzleOpening_%d"%side,.006,.001,Vector3(x,.735,.167),cavity,false)
	bevel(dispenser,"Dispenser_ValveMountPanel",Vector3(.277,.065,.018),Vector3(0,.788,.097),paint,.003)
	for i in range(7):
		box(dispenser,"Dispenser_VentSlot_%02d"%i,Vector3(.187,.004,.002),Vector3(0,.170+i*.012,.183),cavity)
	for x in [-.126,.126]:
		for y in [.100,.535]:cylinder(dispenser,"Dispenser_PanelScrew_%d_%d"%[int(x*100),int(y*100)],.0035,.002,Vector3(x,y,.184),chrome)
	for side in [-1,1]:
		var led=material(Color(.08,.19,.08) if side<0 else Color(.28,.055,.025),.35)
		cylinder(dispenser,"Dispenser_StatusLED_%d"%side,.003,.001,Vector3(side*.044,.913,.191),led)
	var plaque=TextMesh.new()
	plaque.font=load("res://assets/fonts/BarlowCondensed-Bold.ttf")
	plaque.text="AQUA / 02"
	plaque.font_size=40
	plaque.pixel_size=.00022
	plaque.depth=.00005
	add_mesh(dispenser,"Dispenser_BrandPlate",plaque,cavity,Vector3(0,.865,.192))
	cylinder(dispenser,"Dispenser_BottleSeat",.081,.025,Vector3(0,1.022,0),rubber,false)
	var blue=material(Color(.05,.21,.36,.65),.22)
	blue.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	blue.metallic_specular=.65
	var jug_profile=[Vector2(.039,1.032),Vector2(.045,1.047),Vector2(.046,1.088),Vector2(.090,1.114),Vector2(.136,1.160),Vector2(.149,1.208),Vector2(.151,1.244),Vector2(.148,1.42),Vector2(.145,1.483),Vector2(.129,1.509),Vector2(.07,1.522),Vector2(.001,1.522)]
	add_mesh(dispenser,"Dispenser_BlueWaterJug",lathe(jug_profile),blue)
	var water_mat=material(Color(.025,.12,.21),.18)
	add_mesh(dispenser,"Dispenser_JugWater",lathe([Vector2(.001,1.102),Vector2(.09,1.125),Vector2(.137,1.17),Vector2(.143,1.22),Vector2(.143,1.404),Vector2(.001,1.404)]),water_mat)
	for y in [1.233,1.267,1.422,1.464]:
		var rib=TorusMesh.new()
		rib.inner_radius=.145
		rib.outer_radius=.155
		rib.rings=96
		rib.ring_segments=12
		add_mesh(dispenser,"Dispenser_JugRib_%d"%int(y*1000),rib,blue,Vector3(0,y,0))
	cylinder(dispenser,"Dispenser_JugNeckCollar",.048,.019,Vector3(0,1.041,0),material(Color(.07,.12,.15),.38),false)
	# The floor contact and independent enclosure make this a usable native asset.
	var collider=StaticBody3D.new()
	dispenser.add_child(collider)
	var shape=CollisionShape3D.new()
	var box_shape=BoxShape3D.new()
	box_shape.size=Vector3(.38,1.02,.38)
	shape.shape=box_shape
	shape.position=Vector3(0,.51,0)
	collider.add_child(shape)
	var lights=room.get_node("Lighting")
	var bounce=lights.get_node_or_null("WaterStation_Bounce")
	if not bounce:
		bounce=OmniLight3D.new()
		bounce.name="WaterStation_Bounce"
		lights.add_child(bounce)
	bounce.position=Vector3(-2.70,1.80,-1.30)
	bounce.light_color=Color(.76,.82,.76)
	bounce.light_energy=.16
	bounce.omni_range=2.5
	bounce.shadow_enabled=false
	bounce.light_bake_mode=Light3D.BAKE_STATIC
	print("REFINED_DISPENSER ",dispenser.get_child_count())

func build_wardrobe()->void:
	var architecture=room.get_node("Architecture")
	var old=architecture.get_node_or_null("AdjacentWardrobe")
	if old:old.free()
	var wardrobe=Node3D.new()
	wardrobe.name="AdjacentWardrobe"
	architecture.add_child(wardrobe)
	wardrobe.position=Vector3(2.47,.008,-2.40)
	var original=load("res://assets/finished/locker.tscn").instantiate()
	var paint=original.find_child("Locker_Door",true,false).get_active_material(0).duplicate()
	paint.uv1_triplanar=true
	paint.uv1_scale=Vector3(1.1,1.1,1.1)
	var edge=material(Color(.045,.058,.049),.71,.6)
	var steel=material(Color(.11,.125,.11),.49,.78)
	for side in [-1,1]:bevel(wardrobe,"Wardrobe_Side_%d"%side,Vector3(.026,2.16,.65),Vector3(side*.405,1.10,0),paint,.004)
	bevel(wardrobe,"Wardrobe_Back",Vector3(.80,2.16,.020),Vector3(0,1.10,-.315),paint,.004)
	for y in [.045,2.193]:bevel(wardrobe,"Wardrobe_Cap_%d"%int(y*100),Vector3(.85,.034,.685),Vector3(0,y,0),paint,.005)
	for x in [-.355,.355]:
		for z in [-.26,.26]:bevel(wardrobe,"Wardrobe_Foot_%d_%d"%[int(x*100),int(z*100)],Vector3(.047,.080,.06),Vector3(x,.04,z),edge,.003)
	for y in [.16,1.92]:box(wardrobe,"Wardrobe_Shelf_%d"%int(y*100),Vector3(.78,.018,.60),Vector3(0,y,0),paint)
	var rail=cylinder(wardrobe,"Wardrobe_ClothesRail",.012,.75,Vector3(0,1.78,-.04),steel,false)
	rail.rotation.z=PI/2
	# Low-poly cloth silhouettes with shoulders, sleeves and an open hem.
	var cloth=material(Color(.28,.29,.26),.98)
	for k in range(2):
		var hanger=Node3D.new()
		hanger.name="Wardrobe_HangingCoat_%d"%k
		wardrobe.add_child(hanger)
		hanger.position=Vector3(-.13+k*.26,0,-.10)
		var silhouette=PackedVector2Array([Vector2(-.10,.92),Vector2(.10,.92),Vector2(.102,1.47),Vector2(.142,1.15),Vector2(.197,1.17),Vector2(.152,1.58),Vector2(.055,1.66),Vector2(.026,1.63),Vector2(-.026,1.63),Vector2(-.055,1.66),Vector2(-.152,1.58),Vector2(-.197,1.17),Vector2(-.142,1.15),Vector2(-.102,1.47)])
		add_mesh(hanger,"Coat_ShapedBodyAndSleeves",hand_mesh(silhouette,.055),cloth)
		box(hanger,"Coat_ButtonSeam",Vector3(.003,.63,.001),Vector3(0,1.27,.028),edge)
		var hook=add_mesh(hanger,"Coat_Hanger",lathe([Vector2(.002,1.64),Vector2(.008,1.67),Vector2(.008,1.78),Vector2(.002,1.79)],24),steel)
		for y in [1.12,1.28,1.44]:cylinder(hanger,"Coat_Button_%d"%int(y*100),.003,.002,Vector3(.008,y,.030),edge)
	var interior_bounce=OmniLight3D.new()
	interior_bounce.name="Wardrobe_InteriorBounce"
	wardrobe.add_child(interior_bounce)
	interior_bounce.position=Vector3(0,1.55,.22)
	interior_bounce.light_color=Color(.74,.78,.70)
	interior_bounce.light_energy=.055
	interior_bounce.omni_range=1.20
	interior_bounce.shadow_enabled=false
	interior_bounce.light_bake_mode=Light3D.BAKE_STATIC
	var hinge=Node3D.new()
	hinge.name="Wardrobe_DoorHinge"
	wardrobe.add_child(hinge)
	hinge.position=Vector3(.394,.075,.343)
	hinge.rotation.y=.87
	bevel(hinge,"Wardrobe_Door",Vector3(.78,2.075,.025),Vector3(.390,1.0375,0),paint,.004)
	for y in [.22,1.72]:
		box(hinge,"Wardrobe_VentRecess_%d"%int(y*100),Vector3(.52,.16,.002),Vector3(.39,y,.014),edge)
		for i in range(4):
			var vent=box(hinge,"Wardrobe_Louver_%d_%d"%[int(y*100),i],Vector3(.535,.023,.018),Vector3(.39,y-.059+i*.039,.023),paint)
			vent.rotation.x=-.22
	for y in [.35,1.75]:cylinder(hinge,"Wardrobe_HingePin_%d"%int(y*100),.011,.085,Vector3(.0,y,-.008),steel,false)
	bevel(hinge,"Wardrobe_HandleBackplate",Vector3(.038,.115,.012),Vector3(.700,.970,.020),steel,.003)
	bevel(hinge,"Wardrobe_Handle",Vector3(.014,.085,.022),Vector3(.700,.979,.041),edge,.003)
	bevel(hinge,"Wardrobe_NumberPlate",Vector3(.11,.036,.002),Vector3(.39,1.94,.015),material(Color(.32,.24,.12),.68,.5),.0005)
	var digits=TextMesh.new()
	digits.text="08"
	digits.font=load("res://assets/fonts/BarlowCondensed-Bold.ttf")
	digits.font_size=48
	digits.pixel_size=.00040
	digits.depth=.0001
	add_mesh(hinge,"Wardrobe_Number",digits,edge,Vector3(.39,1.94,.017))
	for child in hinge.get_children():child.position.x=-child.position.x
	for n in wardrobe.find_children("*","MeshInstance3D",true,false):n.create_trimesh_collision()
	original.free()
	# Move only the existing top cartons and their attached labels onto the new top height.
	for n in architecture.find_children("*","MeshInstance3D",true,false):
		var label=String(n.name)
		if label in ["Extra_archive_carton_001","Archive_box_label_001","Box_id_001"]:n.hide()
		elif label in ["Extra_archive_carton","Archive_box_label","Box_id"]:
			if not n.has_meta("refined_contact"):
				n.position+=Vector3(0,-.179,-.09)
				n.set_meta("refined_contact",true)
			if not n.has_meta("refined_narrow_top"):
				n.position.x+=.15
				n.set_meta("refined_narrow_top",true)
		elif label=="Cardboard box" and not n.has_meta("refined_contact"):
			n.position+=Vector3(.30,-.194,-.09)
			n.set_meta("refined_contact",true)
	print("REFINED_WARDROBE ",wardrobe.get_child_count())

func refine_locker_door()->void:
	var locker=load("res://assets/finished/locker.tscn").instantiate()
	locker.scene_file_path=""
	var door=locker.find_child("Locker_Door",true,false)
	for n in door.get_children():
		if String(n.name).begins_with("Locker_PressedEdge"):n.free()
	var paint=door.get_active_material(0)
	for name_ in ["Locker_Body","Locker_BackPanel","Locker_TopShelf"]:
		var panel=locker.find_child(name_,true,false)
		panel.material_override=paint.duplicate()
		panel.material_override.uv1_triplanar=true
		panel.material_override.uv1_scale=Vector3(1.1,1.1,1.1)
	for x in [.025,1.165]:bevel(door,"Locker_PressedEdge_V_%d"%int(x*100),Vector3(.014,2.24,.006),Vector3(x,1.155,.027),paint,.002)
	for y in [.035,2.275]:bevel(door,"Locker_PressedEdge_H_%d"%int(y*100),Vector3(1.14,.015,.006),Vector3(.595,y,.027),paint,.002)
	own_all(locker,locker)
	var packed=PackedScene.new()
	assert(packed.pack(locker)==OK)
	assert(ResourceSaver.save(packed,"res://assets/finished/locker.tscn")==OK)
	locker.free()

func fit_portal_surround()->void:
	# Keep the actual opening behind the mirror, but cover the newly exposed
	# strip around the smaller cabinet with the room's own plaster material.
	var architecture=room.get_node("Architecture")
	var old=architecture.get_node_or_null("LockerPortalSurround")
	if old:old.free()
	var surround=Node3D.new()
	surround.name="LockerPortalSurround"
	architecture.add_child(surround)
	var header=architecture.find_child("Wall_LockerPortal_Header",true,false)
	var plaster=header.get_active_material(0)
	box(surround,"Portal_LeftWallInfill",Vector3(.15,2.07,.16),Vector3(.955,1.035,-2.88),plaster).create_trimesh_collision()
	box(surround,"Portal_HeaderInfill",Vector3(.98,.18,.16),Vector3(1.37,2.16,-2.88),plaster).create_trimesh_collision()

func build_clock()->void:
	var clock=Node3D.new()
	clock.name="IndustrialWallClock"
	var metal=material(Color.WHITE,.64,.72)
	metal.albedo_texture=load(MAPS+"clock_metal.png")
	metal.roughness_texture=load(MAPS+"clock_metal_roughness.png")
	var aged_brass=material(Color(.27,.21,.105),.53,.72)
	var edge=material(Color(.055,.051,.039),.48,.75)
	var ink=material(Color(.012,.014,.012),.91,.05)
	var steel=material(Color(.14,.145,.12),.36,.83)
	cylinder(clock,"Clock_Back",.304,.018,Vector3(0,0,-.026),metal)
	cylinder(clock,"Clock_CaseSide",.317,.070,Vector3(0,0,.014),metal)
	ring(clock,"Clock_BackSeam",.310,.318,-.014,edge)
	ring(clock,"Clock_Frame",.289,.326,.055,metal)
	ring(clock,"Clock_BezelWornEdge",.291,.296,.069,aged_brass)
	ring(clock,"Clock_RecessRing",.282,.291,.060,edge)
	var dial=material(Color.WHITE,.97)
	dial.albedo_texture=load(MAPS+"clock_dial.png")
	add_mesh(clock,"Clock_Face",disk(.285),dial,Vector3(0,0,.056))
	for i in range(60):
		var angle=TAU*i/60
		var long_=i%5==0
		var tick=box(clock,"Clock_Tick_%02d"%i,Vector3(.0032 if long_ else .0012,.015 if long_ else .006,.00035),Vector3(sin(angle)*.269,cos(angle)*.269,.057),ink)
		tick.rotation.z=-angle
	var font=load("res://assets/fonts/BarlowCondensed-Bold.ttf")
	for digit in range(1,13):
		var mesh=TextMesh.new()
		mesh.text=str(digit)
		mesh.font=font
		mesh.font_size=80
		mesh.pixel_size=.00080
		mesh.depth=.0001
		var angle=TAU*digit/12
		add_mesh(clock,"Clock_Number_%02d"%digit,mesh,ink,Vector3(sin(angle)*.229,cos(angle)*.229,.0575))
	var branding=TextMesh.new()
	branding.font=font
	branding.text="INTERNATIONAL"
	branding.font_size=40
	branding.pixel_size=.000185
	branding.depth=.0001
	add_mesh(clock,"Clock_DialMaker",branding,ink,Vector3(0,.100,.0576))
	var small=branding.duplicate()
	small.text="ELECTRIC  /  50 Hz"
	small.pixel_size=.00012
	add_mesh(clock,"Clock_DialRating",small,ink,Vector3(0,-.112,.0576))
	add_mesh(clock,"Clock_HourHand",hand_mesh(PackedVector2Array([Vector2(-.004,-.037),Vector2(.004,-.037),Vector2(.0055,.100),Vector2(.003,.162),Vector2(0,.177),Vector2(-.003,.162),Vector2(-.0055,.100)])),ink,Vector3(0,0,.066))
	add_mesh(clock,"Clock_MinuteHand",hand_mesh(PackedVector2Array([Vector2(-.003,-.043),Vector2(.003,-.043),Vector2(.0035,.150),Vector2(.002,.221),Vector2(0,.240),Vector2(-.002,.221),Vector2(-.0035,.150)])),ink,Vector3(0,0,.071))
	cylinder(clock,"Clock_Pivot",.009,.008,Vector3(0,0,.075),steel)
	cylinder(clock,"Clock_PivotRivet",.003,.0015,Vector3(0,0,.080),aged_brass)
	var glass=material(Color(.82,.89,.86,.055),.13)
	glass.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.metallic_specular=.12
	glass.cull_mode=BaseMaterial3D.CULL_DISABLED
	var cover=add_mesh(clock,"Clock_Glass",glass_dome(),glass,Vector3(0,0,.079))
	cover.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for i in range(4):
		var a=TAU*(i+.5)/4
		cylinder(clock,"Clock_CaseScrew_%d"%i,.003,.002,Vector3(sin(a)*.307,cos(a)*.307,.071),steel)
	box(clock,"Clock_WallHanger",Vector3(.028,.055,.012),Vector3(0,.278,-.043),metal)
	# Sub-millimetre printed marks and thin hands should not cast low-resolution
	# realtime shadow-map silhouettes across the readable dial.
	for n in clock.get_children():
		if n is MeshInstance3D and (String(n.name).begins_with("Clock_Number") or String(n.name).begins_with("Clock_Tick") or n.name in ["Clock_HourHand","Clock_MinuteHand","Clock_DialMaker","Clock_DialRating","Clock_Pivot","Clock_PivotRivet"]):
			n.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	own_all(clock,clock)
	var packed=PackedScene.new()
	assert(packed.pack(clock)==OK)
	assert(ResourceSaver.save(packed,"res://assets/finished/clock.tscn")==OK)
	clock.free()
	print("REFINED_CLOCK_SAVED")

func run()->void:
	room=load("res://room_decor.scn").instantiate()
	root.add_child(room)
	room.scene_file_path=""
	build_floor()
	build_fixture()
	build_clock()
	build_dispenser()
	build_wardrobe()
	refine_locker_door()
	fit_portal_surround()
	# New geometry needs a fresh bake. Keep the baked resource path for the editor helper.
	room.get_node("BakedIndirectLight").light_data=LightmapGIData.new()
	own_all(room,room)
	var packed=PackedScene.new()
	assert(packed.pack(room)==OK)
	assert(ResourceSaver.save(packed,"res://room_decor.scn",ResourceSaver.FLAG_COMPRESS)==OK)
	print("ROOM_REFINEMENT_SAVED")
	room.queue_free()
	await process_frame
	quit()

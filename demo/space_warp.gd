class_name SpaceWarp
extends RefCounted

# Same mapping as space_warp.gdshader. Canonical positions remain the navigation
# coordinates; every visible surface uses this continuous world-space mapping.
static func point(p: Vector3, strength: float) -> Vector3:
	var depth := clampf((5.0 - p.z) / 10.0, 0.0, 1.0)
	var bend := strength * 0.65
	return Vector3(
		p.x * (1.0 - bend * 0.20 * depth) + bend * (0.40 * p.y * (0.25 + 0.75 * depth) + 0.18 * p.z * depth),
		p.y * (1.0 - bend * 0.14 * depth) + bend * (-0.20 * p.x * depth + 0.032 * p.x * p.x * depth + 0.20 * depth * (1.0 - depth)),
		p.z + bend * (0.15 * p.x * depth + 0.025 * p.x * p.y + 0.24 * p.y * depth)
	) * compression(strength)

static func compression(strength: float) -> Vector3:
	return Vector3(1.0 - 0.38 * strength, 1.0 - 0.20 * strength, 1.0 - 0.38 * strength)

static func attached_point(p: Vector3, strength: float, anchor: Vector3) -> Vector3:
	# Cancel global shrinking within each prop; retain local shear and stretching.
	return point(anchor + (p - anchor) / compression(strength), strength)

static func attached_basis(p: Vector3, strength: float, anchor: Vector3) -> Basis:
	return jacobian(anchor + (p - anchor) / compression(strength), strength) * Basis.from_scale(Vector3.ONE / compression(strength))

static func floor_position(world: Vector3, strength: float) -> Vector3:
	# Invert the horizontal floor mapping to preserve world movement speed and
	# avoid pulling the viewer toward the center as the walls approach.
	var p := Vector3(world.x, 0, world.z) / compression(strength)
	for i in range(6):
		var offset := point(p, strength) - world
		var j := jacobian(p, strength)
		var det := j.x.x * j.z.z - j.z.x * j.x.z
		p.x -= (j.z.z * offset.x - j.z.x * offset.z) / det
		p.z -= (-j.x.z * offset.x + j.x.x * offset.z) / det
	return p

static func footprint(strength: float) -> float:
	var vertices: Array[Vector3] = []
	for side in range(4):
		for i in range(32):
			var u := float(i) / 32.0
			var p: Vector3
			match side:
				0: p = Vector3(lerpf(-5, 5, u), 0, -5)
				1: p = Vector3(5, 0, lerpf(-5, 5, u))
				2: p = Vector3(lerpf(5, -5, u), 0, 5)
				3: p = Vector3(-5, 0, lerpf(5, -5, u))
			vertices.append(point(p, strength))
	var area := 0.0
	for i in range(vertices.size()):
		var a := vertices[i]
		var b := vertices[(i + 1) % vertices.size()]
		area += a.x * b.z - b.x * a.z
	return absf(area) * 0.5

static func jacobian(p: Vector3, strength: float) -> Basis:
	const EPS := 0.005
	return Basis(
		(point(p + Vector3(EPS, 0, 0), strength) - point(p - Vector3(EPS, 0, 0), strength)) / (2.0 * EPS),
		(point(p + Vector3(0, EPS, 0), strength) - point(p - Vector3(0, EPS, 0), strength)) / (2.0 * EPS),
		(point(p + Vector3(0, 0, EPS), strength) - point(p - Vector3(0, 0, EPS), strength)) / (2.0 * EPS)
	)

static func shell_face(origin: Vector3, across: Vector3, up: Vector3, inward: Vector3) -> ArrayMesh:
	# Equal edge samples on all six surfaces prevent divergent boundary curves.
	const STEPS := 32
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var indices := PackedInt32Array()
	for j in range(STEPS + 1):
		for i in range(STEPS + 1):
			vertices.append(origin + across * (float(i) / STEPS) + up * (float(j) / STEPS))
			normals.append(inward)
	for j in range(STEPS):
		for i in range(STEPS):
			var a := j * (STEPS + 1) + i
			if across.cross(up).dot(inward) > 0.0:
				indices.append_array(PackedInt32Array([a, a + STEPS + 1, a + 1, a + 1, a + STEPS + 1, a + STEPS + 2]))
			else:
				indices.append_array(PackedInt32Array([a, a + 1, a + STEPS + 1, a + 1, a + STEPS + 2, a + STEPS + 1]))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices
	var result := ArrayMesh.new()
	result.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return result

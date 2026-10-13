class_name SpaceWarp
extends RefCounted

# Same mapping as space_warp.gdshader. Canonical positions remain the navigation
# coordinates; every visible surface uses this continuous world-space mapping.
static func point(p: Vector3, strength: float) -> Vector3:
	var depth := clampf((5.0 - p.z) / 10.0, 0.0, 1.0)
	return Vector3(
		p.x * (1.0 - strength * 0.20 * depth) + strength * (0.40 * p.y * (0.25 + 0.75 * depth) + 0.18 * p.z * depth),
		p.y * (1.0 - strength * 0.14 * depth) + strength * (-0.20 * p.x * depth + 0.032 * p.x * p.x * depth + 0.20 * depth * (1.0 - depth)),
		p.z + strength * (0.15 * p.x * depth + 0.025 * p.x * p.y + 0.24 * p.y * depth)
	)

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

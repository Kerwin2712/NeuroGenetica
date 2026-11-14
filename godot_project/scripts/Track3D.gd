extends Node3D
class_name Track3D

@export var track_width: float = 22.0  # Ancho de pista para 4-5 carriles
@export var barrier_height: float = 1.4

var centerline_points: Array[Vector3] = []
var checkpoints: Array[Vector3] = []
var road_mesh_instance: MeshInstance3D
var barrier_inner_instance: MeshInstance3D
var barrier_outer_instance: MeshInstance3D
var static_body_walls: StaticBody3D

func _ready():
	build_track()

func build_track():
	var raw_2d = [
		Vector2(240, 465), Vector2(380, 465), Vector2(520, 465), Vector2(660, 465),
		Vector2(780, 450), Vector2(860, 400), Vector2(890, 310), Vector2(860, 210),
		Vector2(790, 140), Vector2(700, 100), Vector2(610, 110), Vector2(540, 160),
		Vector2(470, 190), Vector2(400, 160), Vector2(340, 110), Vector2(260, 80),
		Vector2(170, 80),  Vector2(100, 130), Vector2(85, 210),  Vector2(110, 280),
		Vector2(140, 340), Vector2(155, 405), Vector2(195, 455)
	]

	# Escalar y centrar a coordenadas 3D
	var base_3d: Array[Vector3] = []
	var scale_factor = 0.65
	for p in raw_2d:
		var x = (p.x - 480.0) * scale_factor
		var z = (p.y - 270.0) * scale_factor
		base_3d.append(Vector3(x, 0.05, z))

	# Suavizado Catmull-Rom para obtener un trazado continuo
	centerline_points.clear()
	var n = base_3d.size()
	var subdivisions = 6

	for i in range(n):
		var p0 = base_3d[(i + n - 1) % n]
		var p1 = base_3d[i]
		var p2 = base_3d[(i + 1) % n]
		var p3 = base_3d[(i + 2) % n]

		for s in range(subdivisions):
			var t = float(s) / float(subdivisions)
			centerline_points.append(catmull_rom_3d(p0, p1, p2, p3, t))

	# Guardar checkpoints cada 8 puntos
	checkpoints.clear()
	for i in range(0, centerline_points.size(), 6):
		checkpoints.append(centerline_points[i])

	# Construir mallas 3D
	generate_road_mesh()
	generate_barriers_and_collisions()
	generate_lane_markings()
	generate_start_finish_line()

func generate_road_mesh():
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var half_w = track_width * 0.5
	var total = centerline_points.size()

	var asphalt_mat = StandardMaterial3D.new()
	asphalt_mat.albedo_color = Color(0.18, 0.19, 0.22)
	asphalt_mat.roughness = 0.85
	asphalt_mat.metallic = 0.1

	for i in range(total):
		var curr = centerline_points[i]
		var nxt = centerline_points[(i + 1) % total]
		var dir = (nxt - curr).normalized()
		var norm = Vector3(-dir.z, 0, dir.x).normalized()

		var curr_left = curr - norm * half_w
		var curr_right = curr + norm * half_w

		var next_curr = centerline_points[(i + 1) % total]
		var next_nxt = centerline_points[(i + 2) % total]
		var next_dir = (next_nxt - next_curr).normalized()
		var next_norm = Vector3(-next_dir.z, 0, next_dir.x).normalized()

		var nxt_left = next_curr - next_norm * half_w
		var nxt_right = next_curr + next_norm * half_w

		# Triángulo 1
		st.set_normal(Vector3.UP)
		st.add_vertex(curr_left)
		st.set_normal(Vector3.UP)
		st.add_vertex(nxt_left)
		st.set_normal(Vector3.UP)
		st.add_vertex(curr_right)

		# Triángulo 2
		st.set_normal(Vector3.UP)
		st.add_vertex(curr_right)
		st.set_normal(Vector3.UP)
		st.add_vertex(nxt_left)
		st.set_normal(Vector3.UP)
		st.add_vertex(nxt_right)

	var road_mesh = st.commit()
	road_mesh_instance = MeshInstance3D.new()
	road_mesh_instance.mesh = road_mesh
	road_mesh_instance.material_override = asphalt_mat
	add_child(road_mesh_instance)

func generate_barriers_and_collisions():
	static_body_walls = StaticBody3D.new()
	static_body_walls.collision_layer = 2 # Capa 2: Muros / Límites
	static_body_walls.collision_mask = 1  # Colisiona con autos
	add_child(static_body_walls)

	var half_w = track_width * 0.5
	var total = centerline_points.size()

	var curb_mat = StandardMaterial3D.new()
	curb_mat.albedo_color = Color(0.85, 0.2, 0.2)
	curb_mat.roughness = 0.5

	# Muros interiores y exteriores
	for is_outer in [false, true]:
		var st = SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)

		for i in range(total):
			var curr = centerline_points[i]
			var nxt = centerline_points[(i + 1) % total]
			var dir = (nxt - curr).normalized()
			var norm = Vector3(-dir.z, 0, dir.x).normalized()
			var offset = (half_w) * (1.0 if is_outer else -1.0)

			var p1 = curr + norm * offset
			var p2 = nxt + norm * offset
			var p1_top = p1 + Vector3(0, barrier_height, 0)
			var p2_top = p2 + Vector3(0, barrier_height, 0)

			# Cara vertical del muro
			st.set_normal(-norm if is_outer else norm)
			st.add_vertex(p1)
			st.set_normal(-norm if is_outer else norm)
			st.add_vertex(p1_top)
			st.set_normal(-norm if is_outer else norm)
			st.add_vertex(p2)

			st.set_normal(-norm if is_outer else norm)
			st.add_vertex(p2)
			st.set_normal(-norm if is_outer else norm)
			st.add_vertex(p1_top)
			st.set_normal(-norm if is_outer else norm)
			st.add_vertex(p2_top)

			# Crear colisión física directa para cada segmento
			var col_shape = CollisionShape3D.new()
			var box = BoxShape3D.new()
			var seg_len = (p2 - p1).length()
			box.size = Vector3(0.6, barrier_height, seg_len)
			col_shape.shape = box
			static_body_walls.add_child(col_shape)
			col_shape.global_position = (p1 + p2) * 0.5 + Vector3(0, barrier_height * 0.5, 0)
			if seg_len > 0.01:
				col_shape.look_at(col_shape.global_position + dir, Vector3.UP)


		var barrier_mesh = st.commit()
		var mesh_inst = MeshInstance3D.new()
		mesh_inst.mesh = barrier_mesh
		mesh_inst.material_override = curb_mat
		add_child(mesh_inst)

func generate_lane_markings():
	# Generar líneas divisorias discontinuas para 4 carriles (3 líneas interiores)
	var lane_offsets = [-5.5, 0.0, 5.5]
	var stripe_mat = StandardMaterial3D.new()
	stripe_mat.albedo_color = Color(1.0, 1.0, 1.0, 0.8)
	stripe_mat.roughness = 0.4

	var total = centerline_points.size()

	for offset in lane_offsets:
		var st = SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)

		for i in range(0, total, 2): # Discontinua (1 tramo sí, 1 no)
			var curr = centerline_points[i]
			var nxt = centerline_points[(i + 1) % total]
			var dir = (nxt - curr).normalized()
			var norm = Vector3(-dir.z, 0, dir.x).normalized()

			var p1 = curr + norm * offset + Vector3(0, 0.08, 0)
			var p2 = nxt + norm * offset + Vector3(0, 0.08, 0)
			var w = 0.18

			st.set_normal(Vector3.UP)
			st.add_vertex(p1 - norm * w)
			st.set_normal(Vector3.UP)
			st.add_vertex(p2 - norm * w)
			st.set_normal(Vector3.UP)
			st.add_vertex(p1 + norm * w)

			st.set_normal(Vector3.UP)
			st.add_vertex(p1 + norm * w)
			st.set_normal(Vector3.UP)
			st.add_vertex(p2 - norm * w)
			st.set_normal(Vector3.UP)
			st.add_vertex(p2 + norm * w)

		var stripes_mesh = st.commit()
		var inst = MeshInstance3D.new()
		inst.mesh = stripes_mesh
		inst.material_override = stripe_mat
		add_child(inst)

func generate_start_finish_line():
	# Línea de meta a cuadros
	var start_idx = 0
	var curr = centerline_points[start_idx]
	var nxt = centerline_points[(start_idx + 1) % centerline_points.size()]
	var dir = (nxt - curr).normalized()
	var norm = Vector3(-dir.z, 0, dir.x).normalized()

	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var start_mat = StandardMaterial3D.new()
	start_mat.albedo_color = Color(1.0, 0.85, 0.2)
	start_mat.emission_enabled = true
	start_mat.emission = Color(1.0, 0.85, 0.2)
	start_mat.emission_energy_multiplier = 0.6

	var p1 = curr - norm * (track_width * 0.5) + Vector3(0, 0.1, 0)
	var p2 = curr + norm * (track_width * 0.5) + Vector3(0, 0.1, 0)
	var line_thickness = 1.6

	st.set_normal(Vector3.UP)
	st.add_vertex(p1)
	st.set_normal(Vector3.UP)
	st.add_vertex(p1 + dir * line_thickness)
	st.set_normal(Vector3.UP)
	st.add_vertex(p2)

	st.set_normal(Vector3.UP)
	st.add_vertex(p2)
	st.set_normal(Vector3.UP)
	st.add_vertex(p1 + dir * line_thickness)
	st.set_normal(Vector3.UP)
	st.add_vertex(p2 + dir * line_thickness)

	var finish_mesh = st.commit()
	var inst = MeshInstance3D.new()
	inst.mesh = finish_mesh
	inst.material_override = start_mat
	add_child(inst)

# Obtener posiciones de la parrilla de salida en 4 carriles (Grid de largada)
func get_starting_grid_transforms(car_count: int) -> Array[Transform3D]:
	var transforms: Array[Transform3D] = []
	var start_idx = 0
	var curr = centerline_points[start_idx]
	var nxt = centerline_points[(start_idx + 1) % centerline_points.size()]
	var forward_dir = (nxt - curr).normalized()
	var normal = Vector3(-forward_dir.z, 0, forward_dir.x).normalized()

	# 4 carriles distribuidos en la pista
	var lane_offsets = [-7.5, -2.5, 2.5, 7.5]
	var row_spacing = 7.5 # Distancia entre filas hacia atrás

	for i in range(car_count):
		var lane_idx = i % 4
		var row_idx = i / 4

		var lane_offset = lane_offsets[lane_idx]
		# Escalonamiento estilo F1 para mayor realismo
		var stagger = (lane_idx % 2) * 2.0
		var pos = curr + (normal * lane_offset) - (forward_dir * (row_idx * row_spacing + stagger))
		pos.y = 0.25

		var t = Transform3D()
		# Orientar auto hacia adelante de la pista
		var basis_z = -forward_dir
		var basis_x = normal
		var basis_y = Vector3.UP
		t.basis = Basis(basis_x, basis_y, basis_z)
		t.origin = pos
		transforms.append(t)

	return transforms

func catmull_rom_3d(p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3, t: float) -> Vector3:
	var t2 = t * t
	var t3 = t2 * t
	return 0.5 * (
		(2.0 * p1) +
		(-p0 + p2) * t +
		(2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2 +
		(-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t3
	)

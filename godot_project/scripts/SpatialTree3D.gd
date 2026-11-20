class_name SpatialTree3D
extends RefCounted

# ==============================================================================
# ESTRUCTURA DE DATOS AVANZADA: Árbol de Partición Espacial 3D (Spatial Tree)
# Materia: Programación 3 - Optimización de Rendimiento
# Autor / Responsable: Kerwin Quintero
#
# Propósito:
#   Indexar la geometría del circuito 3D (puntos de pista, barreras y límites)
#   en una jerarquía de cajas envolventes alineadas a los ejes (AABB 3D).
#   Reduce la complejidad de comprobación de pista y raycasting:
#     - Búsqueda ingenua (fuerza bruta): O(P) por consulta, O(N * P) por fotograma.
#     - Búsqueda en Árbol Espacial: O(log P) por consulta mediante podado espacial.
#   Optimizado para CERO asignaciones de memoria y salida temprana O(1) en pista.
# ==============================================================================

class SpatialNode:
	var bounds: AABB
	var depth: int = 0
	var points: Array[Vector3] = []
	var children: Array[SpatialNode] = []
	var is_divided: bool = false
	var mid_x: float = 0.0
	var mid_z: float = 0.0

	func _init(p_bounds: AABB, p_depth: int = 0):
		bounds = p_bounds
		depth = p_depth
		points = []
		children = []
		is_divided = false
		mid_x = bounds.position.x + (bounds.size.x * 0.5)
		mid_z = bounds.position.z + (bounds.size.z * 0.5)

var root: SpatialNode
var max_points_per_node: int = 4
var max_depth: int = 6
var total_nodes: int = 0
var total_points: int = 0

# Estadísticas de rendimiento para depuración y exposición académica
var total_queries: int = 0
var pruned_branches: int = 0
var evaluated_points: int = 0

func _init(initial_bounds: AABB = AABB(Vector3(-250, -10, -250), Vector3(500, 40, 500)), p_max_points: int = 4, p_max_depth: int = 6):
	max_points_per_node = p_max_points
	max_depth = p_max_depth
	root = SpatialNode.new(initial_bounds, 0)
	total_nodes = 1
	total_points = 0

# ------------------------------------------------------------------------------
# Inserción de un punto 3D en el árbol: O(log N)
# ------------------------------------------------------------------------------
func insert(point: Vector3) -> bool:
	if not root.bounds.has_point(point):
		root.bounds = root.bounds.expand(point)
		root.mid_x = root.bounds.position.x + (root.bounds.size.x * 0.5)
		root.mid_z = root.bounds.position.z + (root.bounds.size.z * 0.5)

	var success = _insert_recursive(root, point)
	if success:
		total_points += 1
	return success

func _insert_recursive(node: SpatialNode, point: Vector3) -> bool:
	if not node.bounds.has_point(point):
		return false

	if not node.is_divided:
		if node.points.size() < max_points_per_node or node.depth >= max_depth:
			node.points.append(point)
			return true
		_subdivide(node)

	for child in node.children:
		if child.bounds.has_point(point):
			return _insert_recursive(child, point)

	node.children[0].bounds = node.children[0].bounds.expand(point)
	return _insert_recursive(node.children[0], point)

func _subdivide(node: SpatialNode):
	var size = node.bounds.size
	var half_x = size.x * 0.5
	var half_z = size.z * 0.5
	var orig = node.bounds.position
	var y = orig.y
	var h = size.y

	var b_nw = AABB(Vector3(orig.x, y, orig.z), Vector3(half_x, h, half_z))
	var b_ne = AABB(Vector3(orig.x + half_x, y, orig.z), Vector3(half_x, h, half_z))
	var b_sw = AABB(Vector3(orig.x, y, orig.z + half_z), Vector3(half_x, h, half_z))
	var b_se = AABB(Vector3(orig.x + half_x, y, orig.z + half_z), Vector3(half_x, h, half_z))

	node.children.append(SpatialNode.new(b_nw, node.depth + 1))
	node.children.append(SpatialNode.new(b_ne, node.depth + 1))
	node.children.append(SpatialNode.new(b_sw, node.depth + 1))
	node.children.append(SpatialNode.new(b_se, node.depth + 1))
	node.is_divided = true
	total_nodes += 4

	var old_points = node.points.duplicate()
	node.points.clear()

	for pt in old_points:
		var placed = false
		for child in node.children:
			if child.bounds.has_point(pt):
				child.points.append(pt)
				placed = true
				break
		if not placed:
			node.children[0].points.append(pt)

# ------------------------------------------------------------------------------
# Verificación ULTRA RÁPIDA de si una posición está en pista: O(log P)
# Cero asignaciones de memoria y salida temprana en O(1) para puntos en pista
# ------------------------------------------------------------------------------
func is_within_track(pos: Vector3, max_half_width: float) -> bool:
	total_queries += 1
	var threshold_sq = max_half_width * max_half_width
	return _check_within_track_fast(root, pos, threshold_sq)

func _check_within_track_fast(node: SpatialNode, pos: Vector3, threshold_sq: float) -> bool:
	# Poda AABB: si la caja completa está más lejos que threshold_sq, podar rama
	if _aabb_distance_squared(node.bounds, pos) > threshold_sq:
		pruned_branches += 1
		return false

	# Comprobar puntos locales del nodo (2 a 4 puntos)
	for pt in node.points:
		evaluated_points += 1
		var dx = pos.x - pt.x
		var dz = pos.z - pt.z
		if (dx * dx + dz * dz) <= threshold_sq:
			return true # ¡Éxito temprano! Retorna de inmediato

	if node.is_divided:
		# Indexación directa del cuadrante contenedor en O(1) sin ordenamientos
		var is_east = 1 if pos.x >= node.mid_x else 0
		var is_south = 2 if pos.z >= node.mid_z else 0
		var primary_idx = is_east + is_south

		# Evaluar primero el cuadrante donde se encuentra el auto
		if _check_within_track_fast(node.children[primary_idx], pos, threshold_sq):
			return true

		# Si no estuvo en el cuadrante primario, revisar los vecinos adyacentes
		for i in range(4):
			if i != primary_idx:
				if _check_within_track_fast(node.children[i], pos, threshold_sq):
					return true

	return false

# ------------------------------------------------------------------------------
# Distancia euclidiana mínima al cuadrado desde un punto hasta una caja AABB
# ------------------------------------------------------------------------------
func _aabb_distance_squared(box: AABB, pos: Vector3) -> float:
	var dx = 0.0
	if pos.x < box.position.x:
		dx = box.position.x - pos.x
	elif pos.x > box.end.x:
		dx = pos.x - box.end.x

	var dz = 0.0
	if pos.z < box.position.z:
		dz = box.position.z - pos.z
	elif pos.z > box.end.z:
		dz = pos.z - box.end.z

	return dx * dx + dz * dz

# ------------------------------------------------------------------------------
# Generador de Malla 3D de Líneas para Visualizar las Divisiones de la Pista (Tecla Q)
# ------------------------------------------------------------------------------
func generate_debug_wireframe_mesh() -> ArrayMesh:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_LINES)

	var col_leaf = Color(0.1, 0.9, 1.0, 0.85)  # Cyan brillante para cuadrantes hoja
	var col_branch = Color(1.0, 0.8, 0.1, 0.7) # Ámbar para subdivisiones intermedias

	_draw_node_bounds(st, root, col_leaf, col_branch)
	return st.commit()

func _draw_node_bounds(st: SurfaceTool, node: SpatialNode, col_leaf: Color, col_branch: Color):
	var b = node.bounds
	var col = col_leaf if not node.is_divided else col_branch
	var y = 0.35 # Ligeramente sobre el asfalto para máxima visibilidad

	var p0 = Vector3(b.position.x, y, b.position.z)
	var p1 = Vector3(b.end.x, y, b.position.z)
	var p2 = Vector3(b.end.x, y, b.end.z)
	var p3 = Vector3(b.position.x, y, b.end.z)

	st.set_color(col)
	st.add_vertex(p0)
	st.add_vertex(p1)

	st.set_color(col)
	st.add_vertex(p1)
	st.add_vertex(p2)

	st.set_color(col)
	st.add_vertex(p2)
	st.add_vertex(p3)

	st.set_color(col)
	st.add_vertex(p3)
	st.add_vertex(p0)

	if node.is_divided:
		for child in node.children:
			_draw_node_bounds(st, child, col_leaf, col_branch)

# ------------------------------------------------------------------------------
# Métricas y Resumen de Eficiencia
# ------------------------------------------------------------------------------
func get_metrics_summary() -> Dictionary:
	return {
		"total_nodes": total_nodes,
		"total_points": total_points,
		"max_depth": max_depth,
		"total_queries": total_queries,
		"pruned_branches": pruned_branches,
		"evaluated_points": evaluated_points
	}

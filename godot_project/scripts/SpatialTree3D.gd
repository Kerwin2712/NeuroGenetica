class_name SpatialTree3D
extends RefCounted

# ==============================================================================
# ESTRUCTURA DE DATOS AVANZADA: Árbol de Partición Espacial 3D (Spatial Tree)
# Materia: Programación 3 - Optimización de Rendimiento
# Autor / Responsable: Kerwin Quintero
#
# Propósito:
#   Indexar la geometría del circuito 3D (puntos de pista, barreras y obstáculos)
#   en una jerarquía de cajas envolventes alineadas a los ejes (AABB 3D).
#   Reduce la complejidad de búsqueda de proximidad y raycasting de sensores:
#     - Búsqueda ingenua (fuerza bruta): O(N) por consulta, O(C * S * N) por fotograma.
#     - Búsqueda en Árbol Espacial: O(log N) por consulta mediante podado espacial.
# ==============================================================================

class SpatialNode:
	var bounds: AABB
	var depth: int = 0
	var points: Array[Vector3] = []
	var children: Array[SpatialNode] = [] # 4 cuadrantes en plano X-Z (QuadTree 3D) u 8 octantes
	var is_divided: bool = false

	func _init(p_bounds: AABB, p_depth: int = 0):
		bounds = p_bounds
		depth = p_depth
		points = []
		children = []
		is_divided = false

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
		# Expandir caja envolvente si el punto está fuera
		root.bounds = root.bounds.expand(point)

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

	# Si está dividido, propagar hacia los hijos
	for child in node.children:
		if child.bounds.has_point(point):
			return _insert_recursive(child, point)

	# Si cae en frontera compartida, guardar en el primer hijo que lo contenga expandido
	node.children[0].bounds = node.children[0].bounds.expand(point)
	return _insert_recursive(node.children[0], point)

# Subdivide un nodo en 4 cuadrantes espaciales a lo largo de los ejes X y Z (plano de carrera)
func _subdivide(node: SpatialNode):
	var size = node.bounds.size
	var half_x = size.x * 0.5
	var half_z = size.z * 0.5
	var orig = node.bounds.position
	var y = orig.y
	var h = size.y

	# 4 subdivisiones espaciales (NW, NE, SW, SE en el plano 3D horizontal)
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

	# Redistribuir los puntos existentes del nodo entre los nuevos hijos
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
# Búsqueda del Punto más Cercano (Nearest Neighbor): O(log N)
# Optimizado con distancias al cuadrado para evitar llamadas costosas a sqrt()
# ------------------------------------------------------------------------------
func get_nearest_distance_squared(query_pos: Vector3) -> float:
	total_queries += 1
	var best_dist_sq = [INF]
	_nearest_recursive(root, query_pos, best_dist_sq)
	return best_dist_sq[0]

func _nearest_recursive(node: SpatialNode, query_pos: Vector3, best_dist_sq: Array):
	# Poda espacial: si la distancia mínima de query_pos al AABB del nodo es mayor
	# o igual que la mejor distancia ya encontrada, podar esta rama completa
	var box_dist_sq = _aabb_distance_squared(node.bounds, query_pos)
	if box_dist_sq >= best_dist_sq[0]:
		pruned_branches += 1
		return

	# Evaluar los puntos contenidos en este nodo
	for pt in node.points:
		evaluated_points += 1
		var dx = query_pos.x - pt.x
		var dz = query_pos.z - pt.z
		var d2 = dx * dx + dz * dz
		if d2 < best_dist_sq[0]:
			best_dist_sq[0] = d2

	if node.is_divided:
		# Ordenar los hijos por proximidad para visitar primero la rama más prometedora
		# lo que maximiza las oportunidades de podar las demás ramas
		var sorted_children = node.children.duplicate()
		sorted_children.sort_custom(func(a, b):
			return _aabb_distance_squared(a.bounds, query_pos) < _aabb_distance_squared(b.bounds, query_pos)
		)

		for child in sorted_children:
			_nearest_recursive(child, query_pos, best_dist_sq)

# Distancia euclidiana mínima al cuadrado desde un punto hasta un AABB
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
# Verificación ultra-rápida de si una posición está en pista: O(log N)
# ------------------------------------------------------------------------------
func is_within_track(pos: Vector3, max_half_width: float) -> bool:
	var threshold_sq = max_half_width * max_half_width
	var dist_sq = get_nearest_distance_squared(pos)
	return dist_sq <= threshold_sq

# ------------------------------------------------------------------------------
# Consulta de Candidatos en Rango (Sphere / Box Query): O(log N)
# ------------------------------------------------------------------------------
func query_radius(center: Vector3, radius: float, result_points: Array[Vector3]):
	var r2 = radius * radius
	_query_radius_recursive(root, center, r2, result_points)

func _query_radius_recursive(node: SpatialNode, center: Vector3, r2: float, result_points: Array[Vector3]):
	if _aabb_distance_squared(node.bounds, center) > r2:
		pruned_branches += 1
		return

	for pt in node.points:
		var dx = center.x - pt.x
		var dz = center.z - pt.z
		if (dx * dx + dz * dz) <= r2:
			result_points.append(pt)

	if node.is_divided:
		for child in node.children:
			_query_radius_recursive(child, center, r2, result_points)

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

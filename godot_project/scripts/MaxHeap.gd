class_name MaxHeap
extends RefCounted

# ==============================================================================
# ESTRUCTURA DE DATOS AVANZADA: Max-Heap (Montículo Máximo / Cola de Prioridad)
# Materia: Programación 3 - Selección Genética y Ranking
# Autor / Responsable: Kerwin Quintero
#
# Propósito:
#   Administrar la población de vehículos y clasificar a los líderes en tiempo O(k log N).
#   Evita ordenar la lista completa con O(N log N) mediante sort tradicional.
#
# Invariante del Montículo Máximo:
#   Para cualquier nodo en índice i (con i > 0):
#     heap[parent(i)].priority >= heap[i].priority
#   Donde:
#     parent(i) = (i - 1) / 2
#     left_child(i) = 2 * i + 1
#     right_child(i) = 2 * i + 2
# ==============================================================================

class HeapNode:
	var item: Variant
	var priority: float

	func _init(p_item: Variant, p_priority: float):
		item = p_item
		priority = p_priority

var _heap: Array[HeapNode] = []

func _init():
	_heap = []

# Inserción en tiempo O(log N)
func push(item: Variant, priority: float):
	var node = HeapNode.new(item, priority)
	_heap.append(node)
	_sift_up(_heap.size() - 1)

# Extracción del elemento con mayor prioridad en tiempo O(log N)
func pop_max() -> Variant:
	if is_empty():
		push_error("Intento de pop_max en un MaxHeap vacío.")
		return null

	var max_item = _heap[0].item
	var last_node = _heap.pop_back()

	if not _heap.is_empty():
		_heap[0] = last_node
		_sift_down(0)

	return max_item

# Consulta del líder en tiempo O(1)
func peek_max() -> Variant:
	if is_empty():
		return null
	return _heap[0].item

func peek_max_priority() -> float:
	if is_empty():
		return -INF
	return _heap[0].priority

func is_empty() -> bool:
	return _heap.is_empty()

func size() -> int:
	return _heap.size()

func clear():
	_heap.clear()

# ------------------------------------------------------------------------------
# Algoritmos de Restauración de la Propiedad del Montículo
# ------------------------------------------------------------------------------

# Sift-Up (Flotación): restaura el orden hacia la raíz tras una inserción: O(log N)
func _sift_up(index: int):
	while index > 0:
		var parent_idx = (index - 1) / 2
		if _heap[index].priority > _heap[parent_idx].priority:
			# Intercambiar con el padre
			var temp = _heap[index]
			_heap[index] = _heap[parent_idx]
			_heap[parent_idx] = temp
			index = parent_idx
		else:
			break

# Sift-Down (Hundimiento): restaura el orden hacia las hojas tras una extracción: O(log N)
func _sift_down(index: int):
	var heap_size = _heap.size()
	while true:
		var largest = index
		var left_child = 2 * index + 1
		var right_child = 2 * index + 2

		if left_child < heap_size and _heap[left_child].priority > _heap[largest].priority:
			largest = left_child

		if right_child < heap_size and _heap[right_child].priority > _heap[largest].priority:
			largest = right_child

		if largest != index:
			var temp = _heap[index]
			_heap[index] = _heap[largest]
			_heap[largest] = temp
			index = largest
		else:
			break

# ------------------------------------------------------------------------------
# Selección de Top-k Individuos en O(k log N)
# Extrae únicamente a los k mejores competidores para elitismo o podio
# ------------------------------------------------------------------------------
func get_top_k(k: int) -> Array:
	var result: Array = []
	var count = min(k, size())
	for i in range(count):
		result.append(pop_max())
	return result

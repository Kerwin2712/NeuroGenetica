extends Node2D

@export var car_scene: PackedScene = preload("res://scenes/Car.tscn")
@export var population_size: int = 30
@export var mutation_rate: float = 0.10
@export var mutation_magnitude: float = 0.30

var cars: Array[CarAgent] = []
var generation: int = 1
var best_fitness_current: float = 0.0
var best_fitness_all_time: float = 0.0
var generation_timer: float = 0.0
var max_generation_time: float = 30.0

var spawn_pos: Vector2 = Vector2(250.0, 465.0)
var spawn_rot: float = PI / 2.0 # Mirando hacia la derecha

var time_scales = [1.0, 2.0, 5.0]
var time_scale_idx = 0

@onready var hud_gen_label: Label = $CanvasLayer/HUD/VBox/GenLabel
@onready var hud_alive_label: Label = $CanvasLayer/HUD/VBox/AliveLabel
@onready var hud_fitness_label: Label = $CanvasLayer/HUD/VBox/FitnessLabel
@onready var hud_speed_label: Label = $CanvasLayer/HUD/VBox/SpeedLabel
@onready var track_body: StaticBody2D = $TrackWalls

func _ready():
	build_track_geometry()
	spawn_initial_population()
	update_hud()

func _process(delta: float):
	generation_timer += delta

	# Controles de teclado
	if Input.is_action_just_pressed("ui_accept"): # Barra espaciadora
		time_scale_idx = (time_scale_idx + 1) % time_scales.size()
		Engine.time_scale = time_scales[time_scale_idx]
		update_hud()
		
	if Input.is_key_pressed(KEY_R): # Forzar reinicio de generación
		evolve_generation()
		return

	var alive_count = 0
	best_fitness_current = 0.0

	for car in cars:
		if car.is_alive:
			alive_count += 1
		if car.fitness > best_fitness_current:
			best_fitness_current = car.fitness

	if best_fitness_current > best_fitness_all_time:
		best_fitness_all_time = best_fitness_current

	update_hud(alive_count)

	# Si todos chocaron o se agotó el tiempo, evolucionar a la siguiente generación
	if alive_count == 0 or generation_timer >= max_generation_time:
		evolve_generation()

func spawn_initial_population():
	for i in range(population_size):
		var car = car_scene.instantiate() as CarAgent
		add_child(car)
		car.reset(spawn_pos, spawn_rot)
		# Inicializar cerebro C++ aleatorio
		car.brain = GodotBrain.new()
		car.brain.randomize(-1.0, 1.0)
		cars.append(car)

func evolve_generation():
	generation_timer = 0.0
	generation += 1

	# 1. Ordenar individuos por fitness de mayor a menor (Elitismo)
	cars.sort_custom(func(a, b): return a.fitness > b.fitness)

	var num_elites = max(2, int(population_size * 0.20)) # Top 20%
	var new_brains: Array[GodotBrain] = []

	# Conservar a los mejores sin alteración
	for i in range(num_elites):
		var elite_brain = GodotBrain.new()
		elite_brain.set_weights(cars[i].brain.get_weights())
		new_brains.append(elite_brain)

	# Reproducción: Cruce genético y mutación para el resto de la población
	while new_brains.size() < population_size:
		# Selección por ruleta/torneo simple dentro del grupo élite
		var parent_a = new_brains[randi() % num_elites]
		var parent_b = new_brains[randi() % num_elites]

		# Cruce C++ nativo
		var child_brain = parent_a.crossover(parent_b)
		# Mutación C++ nativa
		child_brain.mutate(mutation_rate, mutation_magnitude)
		new_brains.append(child_brain)

	# Asignar cerebros evolucionados y reiniciar autos al punto de salida
	for i in range(population_size):
		cars[i].brain = new_brains[i]
		cars[i].reset(spawn_pos, spawn_rot)

func update_hud(alive_count: int = population_size):
	if hud_gen_label:
		hud_gen_label.text = "🏁 Generación: %d" % generation
	if hud_alive_label:
		hud_alive_label.text = "🏎️ Autos Vivos: %d / %d" % [alive_count, population_size]
	if hud_fitness_label:
		hud_fitness_label.text = "⭐ Mejor Fitness: %.1f (Récord: %.1f)" % [best_fitness_current, best_fitness_all_time]
	if hud_speed_label:
		hud_speed_label.text = "⚡ Velocidad: %.0fx [Espacio para cambiar]" % Engine.time_scale

func build_track_geometry():
	var control_points = [
		Vector2(240, 465), Vector2(380, 465), Vector2(520, 465), Vector2(660, 465),
		Vector2(780, 450), Vector2(860, 400), Vector2(890, 310), Vector2(860, 210),
		Vector2(790, 140), Vector2(700, 100), Vector2(610, 110), Vector2(540, 160),
		Vector2(470, 190), Vector2(400, 160), Vector2(340, 110), Vector2(260, 80),
		Vector2(170, 80),  Vector2(100, 130), Vector2(85, 210),  Vector2(110, 280),
		Vector2(140, 340), Vector2(155, 405), Vector2(195, 455)
	]

	# Suavizado de puntos Catmull-Rom
	var curve_points: PackedVector2Array = []
	var n = control_points.size()
	for i in range(n):
		var p0 = control_points[(i + n - 1) % n]
		var p1 = control_points[i]
		var p2 = control_points[(i + 1) % n]
		var p3 = control_points[(i + 2) % n]
		for s in range(4):
			var t = float(s) / 4.0
			curve_points.append(catmull_rom(p0, p1, p2, p3, t))
	curve_points.append(curve_points[0]) # Cerrar circuito

	# Visualización del asfalto
	var asphalt = $TrackVisual/Asphalt as Line2D
	if asphalt:
		asphalt.points = curve_points
		asphalt.width = 64.0
		asphalt.default_color = Color(0.18, 0.20, 0.23, 1.0)

	var centerline = $TrackVisual/Centerline as Line2D
	if centerline:
		centerline.points = curve_points
		centerline.width = 2.0
		centerline.default_color = Color(1.0, 1.0, 1.0, 0.35)

	# Generar paredes colisionables (muro interior y muro exterior a distancia width/2)
	var half_width = 32.0
	var inner_pts: PackedVector2Array = []
	var outer_pts: PackedVector2Array = []

	var total = curve_points.size()
	for i in range(total - 1):
		var p = curve_points[i]
		var next_p = curve_points[(i + 1) % (total - 1)]
		var dir = (next_p - p).normalized()
		var normal = Vector2(-dir.y, dir.x)

		inner_pts.append(p - normal * half_width)
		outer_pts.append(p + normal * half_width)

	inner_pts.append(inner_pts[0])
	outer_pts.append(outer_pts[0])

	# Colisión de muros con StaticBody2D
	create_boundary_collision(inner_pts)
	create_boundary_collision(outer_pts)

func create_boundary_collision(points: PackedVector2Array):
	for i in range(points.size() - 1):
		var seg = CollisionShape2D.new()
		var shape = SegmentShape2D.new()
		shape.a = points[i]
		shape.b = points[i + 1]
		seg.shape = shape
		track_body.add_child(seg)

func catmull_rom(p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2, t: float) -> Vector2:
	var t2 = t * t
	var t3 = t2 * t
	return 0.5 * (
		(2.0 * p1) +
		(-p0 + p2) * t +
		(2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2 +
		(-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t3
	)


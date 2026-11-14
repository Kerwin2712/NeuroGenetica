extends Node3D
class_name SimulationManager3D

@export var car_scene: PackedScene = preload("res://scenes/Car3D.tscn")
@export var default_car_count: int = 10   # 10 autos en parrilla (4, 4, 2)
@export var max_cars: int = 40
@export var min_cars: int = 2

# Modo Copa y Evolución
var current_car_count: int = 10
var cup_round: int = 1
var generation: int = 1
var round_timer: float = 0.0
var max_round_time: float = 45.0 # Segundos por ronda

var cars: Array[Car3D] = []
var cup_points: Dictionary = {}  # { car_id: puntos_acumulados }
var focused_car_idx: int = 0

# Paleta de colores distintivos
var car_colors = [
	Color(0.15, 0.55, 1.0),   # 1: Azul eléctrico
	Color(0.95, 0.2, 0.2),    # 2: Rojo Ferrari
	Color(0.2, 0.85, 0.3),    # 3: Verde lima
	Color(1.0, 0.85, 0.1),    # 4: Amarillo racing
	Color(1.0, 0.5, 0.1),     # 5: Naranja neón
	Color(0.7, 0.2, 0.9),     # 6: Púrpura
	Color(0.1, 0.85, 0.85),   # 7: Turquesa / Cian
	Color(0.9, 0.9, 0.95),    # 8: Blanco perla
	Color(0.95, 0.3, 0.6),    # 9: Rosa deportivo
	Color(0.6, 0.8, 0.2),     # 10: Verde pistacho
	Color(0.4, 0.3, 0.8),     # 11: Índigo
	Color(0.9, 0.7, 0.5)      # 12+: Dorado suave
]

# Referencias
@onready var track: Track3D = $Track3D
@onready var camera_rig: CameraRig3D = $CameraRig3D

# HUD Nodos
@onready var hud_round_label: Label = $CanvasLayer/HUD/LeftPanel/VBox/RoundLabel
@onready var hud_alive_label: Label = $CanvasLayer/HUD/LeftPanel/VBox/AliveLabel
@onready var hud_speed_label: Label = $CanvasLayer/HUD/LeftPanel/VBox/SpeedLabel
@onready var hud_car_name: Label = $CanvasLayer/HUD/RightPanel/VBox/CarNameLabel
@onready var hud_car_mode: Label = $CanvasLayer/HUD/RightPanel/VBox/CarModeLabel
@onready var hud_car_hp_bar: ProgressBar = $CanvasLayer/HUD/RightPanel/VBox/HpBar
@onready var hud_car_speed: Label = $CanvasLayer/HUD/RightPanel/VBox/SpeedLabel
@onready var hud_cam_mode: Label = $CanvasLayer/HUD/RightPanel/VBox/CamModeLabel
@onready var hud_leaderboard: Label = $CanvasLayer/HUD/BottomPanel/LeaderboardLabel

var time_scales = [1.0, 2.0, 4.0]
var time_scale_idx = 0

func _ready():
	current_car_count = default_car_count
	# Inicializar la primera generación en la parrilla
	spawn_race_grid(current_car_count)
	update_camera_target()
	update_hud()

func _process(delta: float):
	round_timer += delta

	# Manejo de atajos de teclado
	handle_inputs()

	# Conteo de autos vivos y cálculo de posiciones
	var alive_count = 0
	for car in cars:
		if car.is_alive:
			alive_count += 1

	update_hud(alive_count)

	# Fin de ronda: todos destruidos o tiempo cumplido
	if alive_count == 0 or round_timer >= max_round_time:
		advance_cup_round()

func _unhandled_input(event: InputEvent):
	if not (event is InputEventKey) or not event.is_pressed() or event.is_echo():
		return

	var key = (event as InputEventKey).keycode

	# Tecla C: Cambiar auto enfocado
	if key == KEY_C:
		if event.shift_pressed:
			cycle_focused_car(-1)
		else:
			cycle_focused_car(1)

	# Tecla V: Alternar perspectiva de cámara (GTA Cenital -> Isométrica -> 3ª Persona -> Panorámica)
	elif key == KEY_V:
		camera_rig.cycle_camera_mode()
		update_hud()

	# Tecla M: Alternar Conducción Manual (Jugador) en el auto enfocado
	elif key == KEY_M:
		var focused = get_focused_car()
		if focused:
			focused.is_player = not focused.is_player
			update_hud()

	# Tecla Espacio: Velocidad de simulación
	elif key == KEY_SPACE:
		time_scale_idx = (time_scale_idx + 1) % time_scales.size()
		Engine.time_scale = time_scales[time_scale_idx]
		update_hud()

	# Tecla R: Forzar fin de ronda / Siguiente carrera
	elif key == KEY_R:
		advance_cup_round()

func handle_inputs():
	# Manejado limpiamente vía _unhandled_input
	pass


func spawn_race_grid(count: int):
	# Limpiar autos anteriores
	for car in cars:
		car.queue_free()
	cars.clear()

	var grid_transforms = track.get_starting_grid_transforms(count)

	for i in range(count):
		var car = car_scene.instantiate() as Car3D
		add_child(car)
		car.car_id = i + 1
		car.car_name = "Auto #%d" % (i + 1)
		var color = car_colors[i % car_colors.size()]
		car.set_car_color(color)

		# Cerebro C++ inicial
		car.brain = GodotBrain.new()
		car.brain.randomize(-1.0, 1.0)

		# Posición en la parrilla (4 carriles escalonados)
		car.reset_car(grid_transforms[i])
		cars.append(car)

		if not cup_points.has(car.car_id):
			cup_points[car.car_id] = 0

	focused_car_idx = 0
	update_camera_target()

func advance_cup_round():
	round_timer = 0.0
	cup_round += 1
	generation += 1

	# 1. Clasificar autos por fitness (distancia + salud)
	cars.sort_custom(func(a, b): return a.fitness > b.fitness)

	# Otorgar puntos de Copa a los 5 primeros (25, 18, 15, 10, 8)
	var pts_table = [25, 18, 15, 10, 8, 6, 4, 2, 1, 1]
	for i in range(min(cars.size(), pts_table.size())):
		var cid = cars[i].car_id
		cup_points[cid] = cup_points.get(cid, 0) + pts_table[i]

	# 2. Selección elitista y reproducción en C++
	var num_elites = max(2, int(cars.size() * 0.25)) # Top 25%
	var new_brains: Array[GodotBrain] = []

	# Conservar a los mejores
	for i in range(num_elites):
		var elite_brain = GodotBrain.new()
		elite_brain.set_weights(cars[i].brain.get_weights())
		new_brains.append(elite_brain)

	# Reproducir con cruce y mutación
	while new_brains.size() < cars.size():
		var parent_a = new_brains[randi() % num_elites]
		var parent_b = new_brains[randi() % num_elites]
		var child = parent_a.crossover(parent_b)
		child.mutate(0.12, 0.25)
		new_brains.append(child)

	# 3. Reubicar en la parrilla de salida
	var grid_transforms = track.get_starting_grid_transforms(cars.size())
	for i in range(cars.size()):
		cars[i].brain = new_brains[i]
		cars[i].reset_car(grid_transforms[i])

	update_hud()

func cycle_focused_car(direction: int):
	if cars.is_empty():
		return
	focused_car_idx = (focused_car_idx + direction + cars.size()) % cars.size()
	update_camera_target()
	update_hud()

func update_camera_target():
	var car = get_focused_car()
	if car and camera_rig:
		camera_rig.target_car = car

func get_focused_car() -> Car3D:
	if focused_car_idx >= 0 and focused_car_idx < cars.size():
		return cars[focused_car_idx]
	return null

func update_hud(alive_count: int = -1):
	if alive_count == -1:
		alive_count = 0
		for c in cars:
			if c.is_alive: alive_count += 1

	if hud_round_label:
		hud_round_label.text = "🏆 Copa - Ronda %d | Gen %d" % [cup_round, generation]
	if hud_alive_label:
		hud_alive_label.text = "🏎️ Autos en Pista: %d / %d" % [alive_count, cars.size()]
	if hud_speed_label:
		hud_speed_label.text = "⚡ Simulación: %.0fx [Espacio]" % Engine.time_scale

	var focused = get_focused_car()
	if focused:
		if hud_car_name:
			hud_car_name.text = "🎯 Siguiendo: %s" % focused.car_name
			hud_car_name.modulate = focused.car_color
		if hud_car_mode:
			if focused.is_player:
				hud_car_mode.text = "🎮 Modo: JUGADOR HUMANO (WASD)"
				hud_car_mode.modulate = Color(0.3, 1.0, 0.4)
			else:
				hud_car_mode.text = "🧠 Modo: IA ADAPTATIVA (C++)"
				hud_car_mode.modulate = Color(0.4, 0.7, 1.0)
		if hud_car_hp_bar:
			hud_car_hp_bar.value = focused.health
		if hud_car_speed:
			hud_car_speed.text = "Velocidad: %.0f km/h | Vueltas: %d | Choques: %d" % [abs(focused.speed * 3.6), focused.current_lap, focused.total_collisions]
		if hud_cam_mode:
			hud_cam_mode.text = "%s [Tecla V]" % camera_rig.get_mode_name()

	# Clasificación / Leaderboard
	if hud_leaderboard:
		var sorted_cars = cars.duplicate()
		sorted_cars.sort_custom(func(a, b): return a.fitness > b.fitness)
		var text = "🏁 CLASIFICACIÓN EN VIVO:\n"
		for i in range(min(5, sorted_cars.size())):
			var c = sorted_cars[i]
			var status = "%.0f%% HP" % c.health if c.is_alive else "DEAD"
			var pts = cup_points.get(c.car_id, 0)
			text += "%dº %s (%s, %.0fm, %d pts)\n" % [i + 1, c.car_name, status, c.distance_traveled, pts]
		hud_leaderboard.text = text

extends Node3D
class_name SimulationManager3D

enum GameMode {
	SPECTATOR_AI,   # Redes neuronales puras con vista isométrica libre
	PLAYER_RACE     # Entras a la pista con tu auto y compites contra la IA
}

@export var car_scene: PackedScene = preload("res://scenes/Car3D.tscn")
@export var default_car_count: int = 10

var current_game_mode: GameMode = GameMode.SPECTATOR_AI
var current_car_count: int = 10
var cup_round: int = 1
var generation: int = 1
var round_timer: float = 0.0
var max_round_time: float = 50.0

var cars: Array[Car3D] = []
var cup_points: Dictionary = {}
var focused_car_idx: int = 0

var car_colors = [
	Color(1.0, 0.85, 0.1),    # 1: Amarillo Dorado (Jugador / Líder)
	Color(0.95, 0.2, 0.2),    # 2: Rojo
	Color(0.15, 0.55, 1.0),   # 3: Azul
	Color(0.2, 0.85, 0.3),    # 4: Verde lima
	Color(1.0, 0.5, 0.1),     # 5: Naranja
	Color(0.7, 0.2, 0.9),     # 6: Púrpura
	Color(0.1, 0.85, 0.85),   # 7: Turquesa
	Color(0.95, 0.95, 0.95),  # 8: Blanco
	Color(0.95, 0.3, 0.6),    # 9: Rosa
	Color(0.6, 0.8, 0.2)      # 10: Pistacho
]

# Referencias a nodos
@onready var track: Track3D = $Track3D
@onready var camera_rig: CameraRig3D = $CameraRig3D

# HUD
@onready var hud_mode_banner: Label = $CanvasLayer/HUD/TopModeBanner/ModeLabel
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
	spawn_race_grid(current_car_count)
	apply_game_mode()
	update_hud()

func _unhandled_input(event: InputEvent):
	if not (event is InputEventKey) or not event.is_pressed() or event.is_echo():
		return

	var key = (event as InputEventKey).keycode

	# Tecla TAB o P: Alternar entre MODO ESPECTADOR LIBRE y MODO JUGADOR AL VOLANTE
	if key == KEY_TAB or key == KEY_P:
		if current_game_mode == GameMode.SPECTATOR_AI:
			current_game_mode = GameMode.PLAYER_RACE
		else:
			current_game_mode = GameMode.SPECTATOR_AI
		apply_game_mode()
		update_hud()

	# Tecla C: Cambiar auto enfocado
	elif key == KEY_C:
		if event.shift_pressed:
			cycle_focused_car(-1)
		else:
			cycle_focused_car(1)

	# Tecla V: Alternar perspectiva de cámara (Isométrica Libre -> GTA Cenital -> Isométrica Auto -> 3ª Persona)
	elif key == KEY_V:
		camera_rig.cycle_camera_mode()
		update_hud()

	# Tecla M: Alternar Conducción Manual en el auto actualmente enfocado
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

	# Tecla R: Forzar fin de carrera / siguiente ronda de la Copa
	elif key == KEY_R:
		advance_cup_round()

func _process(delta: float):
	round_timer += delta

	var alive_count = 0
	for car in cars:
		if car.is_alive:
			alive_count += 1

	update_hud(alive_count)

	if alive_count == 0 or round_timer >= max_round_time:
		advance_cup_round()

func apply_game_mode():
	if cars.is_empty():
		return

	if current_game_mode == GameMode.PLAYER_RACE:
		# Auto 0 es el jugador
		cars[0].is_player = true
		cars[0].car_name = "TÚ (Jugador 1)"
		cars[0].set_car_color(Color(1.0, 0.85, 0.1)) # Dorado
		focused_car_idx = 0
		camera_rig.current_mode = CameraRig3D.CameraMode.GTA_TOPDOWN
		camera_rig.is_player_driving = true
		camera_rig.focus_on_car(cars[0])
	else:
		# Modo Espectador: todos son IA
		cars[0].is_player = false
		cars[0].car_name = "Auto #1 (IA)"
		camera_rig.current_mode = CameraRig3D.CameraMode.OVERVIEW_ISOMETRIC
		camera_rig.is_player_driving = false
		camera_rig.focus_on_car(cars[focused_car_idx])

func spawn_race_grid(count: int):
	for car in cars:
		car.queue_free()
	cars.clear()

	var grid_transforms = track.get_starting_grid_transforms(count)

	for i in range(count):
		var car = car_scene.instantiate() as Car3D
		add_child(car)
		car.track_ref = track # Vincular pista para detección de pasto
		car.car_id = i + 1
		car.car_name = "Auto #%d" % (i + 1)
		var color = car_colors[i % car_colors.size()]
		car.set_car_color(color)

		# Cerebro C++
		car.brain = GodotBrain.new()
		car.brain.randomize(-1.0, 1.0)

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

	# Clasificar por fitness
	cars.sort_custom(func(a, b): return a.fitness > b.fitness)

	var pts_table = [25, 18, 15, 10, 8, 6, 4, 2, 1, 1]
	for i in range(min(cars.size(), pts_table.size())):
		var cid = cars[i].car_id
		cup_points[cid] = cup_points.get(cid, 0) + pts_table[i]

	# Reproducción y mutación en C++ para los rivales IA
	var num_elites = max(2, int(cars.size() * 0.25))
	var new_brains: Array[GodotBrain] = []

	for i in range(num_elites):
		var elite_brain = GodotBrain.new()
		elite_brain.set_weights(cars[i].brain.get_weights())
		new_brains.append(elite_brain)

	while new_brains.size() < cars.size():
		var parent_a = new_brains[randi() % num_elites]
		var parent_b = new_brains[randi() % num_elites]
		var child = parent_a.crossover(parent_b)
		child.mutate(0.12, 0.25)
		new_brains.append(child)

	# Reubicar en parrilla
	var grid_transforms = track.get_starting_grid_transforms(cars.size())
	for i in range(cars.size()):
		cars[i].brain = new_brains[i]
		cars[i].reset_car(grid_transforms[i])

	apply_game_mode()
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
		camera_rig.focus_on_car(car)

func get_focused_car() -> Car3D:
	if focused_car_idx >= 0 and focused_car_idx < cars.size():
		return cars[focused_car_idx]
	return null

func update_hud(alive_count: int = -1):
	if alive_count == -1:
		alive_count = 0
		for c in cars:
			if c.is_alive: alive_count += 1

	if hud_mode_banner:
		if current_game_mode == GameMode.PLAYER_RACE:
			hud_mode_banner.text = "🎮 MODO PILOTO HUMANO: Conduce con [WASD] contra la IA  |  [TAB]: Modo Espectador Libre"
			hud_mode_banner.modulate = Color(1.0, 0.9, 0.2)
		else:
			hud_mode_banner.text = "👁️ MODO ESPECTADOR: Isométrica Libre (Arrastra ratón / Scroll zoom)  |  [TAB]: Entrar a Conducir"
			hud_mode_banner.modulate = Color(0.4, 0.85, 1.0)

	if hud_round_label:
		hud_round_label.text = "🏆 Modo Copa - Ronda %d | Gen %d" % [cup_round, generation]
	if hud_alive_label:
		hud_alive_label.text = "🏎️ Autos en Pista: %d / %d" % [alive_count, cars.size()]
	if hud_speed_label:
		hud_speed_label.text = "⚡ Simulación: %.0fx [Espacio]" % Engine.time_scale

	var focused = get_focused_car()
	if focused:
		if hud_car_name:
			hud_car_name.text = "🎯 Auto: %s" % focused.car_name
			hud_car_name.modulate = focused.car_color
		if hud_car_mode:
			if focused.is_player:
				hud_car_mode.text = "🎮 [CONTROL HUMANO: WASD/Flechas]"
				hud_car_mode.modulate = Color(0.3, 1.0, 0.4)
			else:
				hud_car_mode.text = "🧠 [RED NEURONAL C++ (GDExtension)]"
				hud_car_mode.modulate = Color(0.4, 0.7, 1.0)
		if hud_car_hp_bar:
			hud_car_hp_bar.value = focused.health
			# Color dinámico de barra
			if focused.is_in_grass:
				hud_car_speed.text = "⚠️ ¡FUERA DE PISTA! Daño continuo en el pasto..."
			else:
				hud_car_speed.text = "Velocidad: %.0f km/h | Vueltas: %d | Choques: %d" % [abs(focused.speed * 3.6), focused.current_lap, focused.total_collisions]
		if hud_cam_mode:
			hud_cam_mode.text = "%s [Tecla V]" % camera_rig.get_mode_name()

	if hud_leaderboard:
		var sorted_cars = cars.duplicate()
		sorted_cars.sort_custom(func(a, b): return a.fitness > b.fitness)
		var text = "🏁 CLASIFICACIÓN EN VIVO:\n"
		for i in range(min(5, sorted_cars.size())):
			var c = sorted_cars[i]
			var status = "%.0f%% HP" % c.health if c.is_alive else "DEAD"
			var tag = " (TÚ)" if c.is_player else ""
			text += "%dº %s%s (%s, %.0fm, %d pts)\n" % [i + 1, c.car_name, tag, status, c.distance_traveled, cup_points.get(c.car_id, 0)]
		hud_leaderboard.text = text

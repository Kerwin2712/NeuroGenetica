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

# Gestión de Equipos de IA y Guardado
var current_team_name: String = "IAs Novatas (Aleatorias)"
var available_teams: Array[String] = [
	"IAs Novatas (Aleatorias)",
	"IAs Calibradas (Curvas Rápidas)",
	"Escudería Élite (Campeones de Copa)"
]
var current_team_idx: int = 0
var toast_message: String = ""
var toast_timer: float = 0.0
var show_telemetry_panel: bool = false

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

# HUD Nodos
@onready var hud_mode_banner: Label = $CanvasLayer/HUD/TopModeBanner/ModeLabel
@onready var hud_round_label: Label = $CanvasLayer/HUD/LeftPanel/VBox/RoundLabel
@onready var hud_alive_label: Label = $CanvasLayer/HUD/LeftPanel/VBox/AliveLabel
@onready var hud_speed_label: Label = $CanvasLayer/HUD/LeftPanel/VBox/SpeedLabel
@onready var hud_team_label: Label = $CanvasLayer/HUD/LeftPanel/VBox/TeamLabel

@onready var hud_car_name: Label = $CanvasLayer/HUD/RightPanel/VBox/CarNameLabel
@onready var hud_car_mode: Label = $CanvasLayer/HUD/RightPanel/VBox/CarModeLabel
@onready var hud_car_hp_bar: ProgressBar = $CanvasLayer/HUD/RightPanel/VBox/HpBar
@onready var hud_car_speed: Label = $CanvasLayer/HUD/RightPanel/VBox/SpeedLabel
@onready var hud_cam_mode: Label = $CanvasLayer/HUD/RightPanel/VBox/CamModeLabel
@onready var hud_leaderboard: Label = $CanvasLayer/HUD/BottomPanel/LeaderboardLabel
@onready var hud_toast_label: Label = $CanvasLayer/HUD/ToastBanner/ToastLabel
@onready var hud_telemetry_window: PanelContainer = $CanvasLayer/HUD/TelemetryWindow
@onready var hud_telemetry_text: RichTextLabel = $CanvasLayer/HUD/TelemetryWindow/VBox/Scroll/Text

var time_scales = [1.0, 2.0, 4.0]
var time_scale_idx = 0

func _ready():
	scan_saved_team_files()
	current_car_count = default_car_count
	spawn_race_grid(current_car_count)
	apply_game_mode()
	update_hud()
	show_toast("🏁 ¡Bienvenido a NeuroGenetica 3D! Pulsa [TAB] para Conducir o [G] para Guardar Generación.")

func _unhandled_input(event: InputEvent):
	if not (event is InputEventKey) or not event.is_pressed() or event.is_echo():
		return

	var key = (event as InputEventKey).keycode

	# TAB o P: Alternar entre MODO ESPECTADOR y MODO JUGADOR
	if key == KEY_TAB or key == KEY_P:
		if current_game_mode == GameMode.SPECTATOR_AI:
			current_game_mode = GameMode.PLAYER_RACE
		else:
			current_game_mode = GameMode.SPECTATOR_AI
		apply_game_mode()
		update_hud()

	# F5 o Shift + R: Reiniciar toda la simulación desde cero
	elif key == KEY_F5 or (key == KEY_R and event.shift_pressed):
		reset_entire_simulation()

	# R (sin Shift): Forzar fin de ronda / Siguiente carrera de la Copa
	elif key == KEY_R:
		advance_cup_round()

	# G: Guardar la generación actual y sus pesos neuronales
	elif key == KEY_G:
		save_current_generation()

	# L o T: Cargar / Alternar entre Equipos de IA disponibles
	elif key == KEY_L or key == KEY_T:
		cycle_ai_team()

	# I: Mostrar / Ocultar ventana de Telemetría Detallada y Estadísticas
	elif key == KEY_I:
		toggle_telemetry_window()

	# C: Cambiar auto enfocado
	elif key == KEY_C:
		if event.shift_pressed:
			cycle_focused_car(-1)
		else:
			cycle_focused_car(1)

	# V: Alternar perspectiva de cámara (Isométrica Libre -> GTA Cenital -> Isométrica Auto -> 3ª Persona)
	elif key == KEY_V:
		camera_rig.cycle_camera_mode()
		update_hud()

	# M: Alternar Conducción Manual en el auto actualmente enfocado
	elif key == KEY_M:
		var focused = get_focused_car()
		if focused:
			focused.is_player = not focused.is_player
			update_hud()

	# Espacio: Velocidad de simulación
	elif key == KEY_SPACE:
		time_scale_idx = (time_scale_idx + 1) % time_scales.size()
		Engine.time_scale = time_scales[time_scale_idx]
		update_hud()

func _process(delta: float):
	round_timer += delta

	# Temporizador para avisos flotantes (Toast)
	if toast_timer > 0.0:
		toast_timer -= delta
		if toast_timer <= 0.0 and hud_toast_label:
			hud_toast_label.get_parent().visible = false

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
		# Auto 0 es el jugador humano
		cars[0].is_player = true
		cars[0].car_name = "TÚ (Jugador 1)"
		cars[0].set_car_color(Color(1.0, 0.85, 0.1)) # Dorado
		focused_car_idx = 0
		camera_rig.current_mode = CameraRig3D.CameraMode.GTA_TOPDOWN
		camera_rig.is_player_driving = true
		camera_rig.focus_on_car(cars[0])
		show_toast("🎮 MODO JUGADOR ACTIVADO: Conduce con [WASD] contra los 9 rivales de IA.")
	else:
		# Modo Espectador: todos son controlados por la IA
		cars[0].is_player = false
		cars[0].car_name = "Auto #1 (IA)"
		camera_rig.current_mode = CameraRig3D.CameraMode.OVERVIEW_ISOMETRIC
		camera_rig.is_player_driving = false
		camera_rig.focus_on_car(cars[focused_car_idx])
		show_toast("👁️ MODO ESPECTADOR: Isométrica Libre (Arrastra ratón / Scroll zoom).")

func spawn_race_grid(count: int):
	for car in cars:
		car.queue_free()
	cars.clear()

	var grid_transforms = track.get_starting_grid_transforms(count)

	for i in range(count):
		var car = car_scene.instantiate() as Car3D
		add_child(car)
		car.track_ref = track
		car.car_id = i + 1
		car.car_name = "Auto #%d" % (i + 1)
		var color = car_colors[i % car_colors.size()]
		car.set_car_color(color)

		# Cerebro C++
		car.brain = GodotBrain.new()
		apply_brain_preset(car.brain, current_team_idx)

		car.reset_car(grid_transforms[i])
		cars.append(car)

		if not cup_points.has(car.car_id):
			cup_points[car.car_id] = 0

	focused_car_idx = 0
	update_camera_target()

func apply_brain_preset(brain: GodotBrain, team_idx: int):
	if team_idx == 0:
		# Novatos: pesos totalmente aleatorios
		brain.randomize(-1.0, 1.0)
	elif team_idx == 1:
		# Calibrados: heurística de curvas y aceleración con ligera variación
		brain.initialize_heuristic()
		brain.mutate(0.08, 0.12)
	elif team_idx == 2:
		# Élite Copa: heurística óptima con alta respuesta de viraje
		brain.initialize_heuristic()
		brain.mutate(0.04, 0.08)

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
		child.mutate(0.10, 0.20)
		new_brains.append(child)

	# Reubicar en parrilla
	var grid_transforms = track.get_starting_grid_transforms(cars.size())
	for i in range(cars.size()):
		cars[i].brain = new_brains[i]
		cars[i].reset_car(grid_transforms[i])

	apply_game_mode()
	update_hud()
	show_toast("🏆 ¡Avanzando a Ronda %d de la Copa! (Generación %d evolucionada)" % [cup_round, generation])

# Reinicio completo de la simulación a estado original
func reset_entire_simulation():
	round_timer = 0.0
	cup_round = 1
	generation = 1
	cup_points.clear()

	var grid_transforms = track.get_starting_grid_transforms(cars.size())
	for i in range(cars.size()):
		apply_brain_preset(cars[i].brain, current_team_idx)
		cars[i].reset_car(grid_transforms[i])
		cup_points[cars[i].car_id] = 0

	apply_game_mode()
	update_hud()
	show_toast("🔄 ¡SIMULACIÓN REINICIADA POR COMPLETO! (Ronda 1, Gen 1, Puntos a 0)")

# Guardar la generación actual y todos sus genomas en disco
func save_current_generation():
	var dir_path = "user://saved_teams"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir_path))

	var time_dict = Time.get_datetime_dict_from_system()
	var filename = "Equipo_Gen%d_%02d%02d_%02d%02d.json" % [
		generation, time_dict["month"], time_dict["day"], time_dict["hour"], time_dict["minute"]
	]
	var full_path = dir_path + "/" + filename

	var team_data = {
		"team_name": "Generación %d (Ronda %d)" % [generation, cup_round],
		"generation": generation,
		"cup_round": cup_round,
		"car_count": cars.size(),
		"date": Time.get_datetime_string_from_system(),
		"cars": []
	}

	for car in cars:
		var weights_array = []
		var flat_w = car.brain.get_weights()
		for w in flat_w:
			weights_array.append(w)

		team_data["cars"].append({
			"car_id": car.car_id,
			"name": car.car_name,
			"top_speed": car.top_speed_kmh,
			"best_lap": car.best_lap_time,
			"training_level": car.training_level,
			"fitness": car.fitness,
			"weights": weights_array
		})

	var json_text = JSON.stringify(team_data, "\t")
	var file = FileAccess.open(full_path, FileAccess.WRITE)
	if file:
		file.store_string(json_text)
		file.close()
		scan_saved_team_files()
		show_toast("💾 ¡Generación guardada con éxito!: %s" % filename)
	else:
		show_toast("❌ Error al guardar el archivo.")

# Cargar el siguiente equipo de IAs disponible
func cycle_ai_team():
	if available_teams.is_empty():
		return

	current_team_idx = (current_team_idx + 1) % available_teams.size()
	current_team_name = available_teams[current_team_idx]

	if current_team_idx < 3:
		# Preset de fábrica (Novatos, Calibrados, Élite)
		for car in cars:
			apply_brain_preset(car.brain, current_team_idx)
	else:
		# Archivo guardado en disco
		load_team_from_file(current_team_name)

	var grid_transforms = track.get_starting_grid_transforms(cars.size())
	for i in range(cars.size()):
		cars[i].reset_car(grid_transforms[i])

	apply_game_mode()
	update_hud()
	show_toast("📂 Equipo de IA seleccionado: '%s'" % current_team_name)

func load_team_from_file(file_name: String):
	var full_path = "user://saved_teams/" + file_name
	if not FileAccess.file_exists(full_path):
		return

	var file = FileAccess.open(full_path, FileAccess.READ)
	var text = file.get_as_text()
	file.close()

	var data = JSON.parse_string(text)
	if data and data.has("cars"):
		var car_list = data["cars"]
		generation = data.get("generation", 1)
		cup_round = data.get("cup_round", 1)

		for i in range(min(cars.size(), car_list.size())):
			var c_data = car_list[i]
			var w_array: Array = c_data.get("weights", [])
			var packed_w = PackedFloat32Array()
			for w in w_array:
				packed_w.append(float(w))
			cars[i].brain.set_weights(packed_w)

func scan_saved_team_files():
	# Reiniciar lista con los 3 de fábrica
	available_teams = [
		"IAs Novatas (Aleatorias)",
		"IAs Calibradas (Curvas Rápidas)",
		"Escudería Élite (Campeones de Copa)"
	]
	var dir_path = "user://saved_teams"
	if DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(dir_path)):
		var dir = DirAccess.open(dir_path)
		if dir:
			dir.list_dir_begin()
			var file_name = dir.get_next()
			while file_name != "":
				if not dir.current_is_dir() and file_name.ends_with(".json"):
					available_teams.append(file_name)
				file_name = dir.get_next()
			dir.list_dir_end()

func toggle_telemetry_window():
	show_telemetry_panel = not show_telemetry_panel
	if hud_telemetry_window:
		hud_telemetry_window.visible = show_telemetry_panel
		if show_telemetry_panel:
			update_telemetry_panel()

func update_telemetry_panel():
	if not hud_telemetry_text:
		return

	var text = "[b]📊 TELEMETRÍA DETALLADA Y NIVEL DE ENTRENAMIENTO:[/b]\n"
	text += "Equipo activo: [color=yellow]%s[/color] | Generación: %d | Ronda: %d\n\n" % [current_team_name, generation, cup_round]
	text += "[table=7]"
	text += "[cell][b]Auto[/b][/cell][cell][b]Nivel[/b][/cell][cell][b]Vel. Punta[/b][/cell][cell][b]Vueltas[/b][/cell][cell][b]Mejor Vuelta[/b][/cell][cell][b]Salud[/b][/cell][cell][b]Puntos[/b][/cell]"

	var sorted_cars = cars.duplicate()
	sorted_cars.sort_custom(func(a, b): return a.fitness > b.fitness)

	for c in sorted_cars:
		var name_str = c.car_name + (" (TÚ)" if c.is_player else "")
		var level_str = "⭐ Nivel %d" % c.training_level
		var speed_str = "%.0f km/h" % c.top_speed_kmh
		var laps_str = "%d" % c.current_lap
		var lap_time_str = ("%.2fs" % c.best_lap_time) if c.best_lap_time < 900.0 else "--"
		var hp_str = ("%.0f%%" % c.health) if c.is_alive else "[color=red]DEAD[/color]"
		var pts_str = "%d pts" % cup_points.get(c.car_id, 0)

		text += "[cell]%s[/cell][cell]%s[/cell][cell]%s[/cell][cell]%s[/cell][cell]%s[/cell][cell]%s[/cell][cell]%s[/cell]" % [
			name_str, level_str, speed_str, laps_str, lap_time_str, hp_str, pts_str
		]

	text += "[/table]\n[color=gray]Pulsa [I] para cerrar esta ventana.[/color]"
	hud_telemetry_text.text = text

func show_toast(msg: String):
	toast_message = msg
	toast_timer = 4.0
	if hud_toast_label:
		hud_toast_label.text = msg
		hud_toast_label.get_parent().visible = true

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
			hud_mode_banner.text = "🎮 MODO PILOTO HUMANO (WASD)  |  [TAB]: Modo Espectador Libre"
			hud_mode_banner.modulate = Color(1.0, 0.9, 0.2)
		else:
			hud_mode_banner.text = "👁️ MODO ESPECTADOR (Arrastra ratón / Scroll zoom)  |  [TAB]: Entrar a Conducir"
			hud_mode_banner.modulate = Color(0.4, 0.85, 1.0)

	if hud_round_label:
		hud_round_label.text = "🏆 Copa - Ronda %d | Gen %d" % [cup_round, generation]
	if hud_alive_label:
		hud_alive_label.text = "🏎️ Autos en Pista: %d / %d" % [alive_count, cars.size()]
	if hud_speed_label:
		hud_speed_label.text = "⚡ Simulación: %.0fx [Espacio]" % Engine.time_scale
	if hud_team_label:
		hud_team_label.text = "🤖 Equipo IA: %s [Tecla L]" % current_team_name

	var focused = get_focused_car()
	if focused:
		if hud_car_name:
			hud_car_name.text = "🎯 Auto: %s (Nivel %d)" % [focused.car_name, focused.training_level]
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
			if focused.is_in_grass:
				hud_car_speed.text = "⚠️ ¡FUERA DE PISTA! Daño continuo en el pasto..."
			else:
				hud_car_speed.text = "Velocidad: %.0f km/h (Máx: %.0f) | Vueltas: %d" % [abs(focused.speed * 3.6), focused.top_speed_kmh, focused.current_lap]
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
			text += "%dº %s%s (Nv.%d, %.0f km/h, %d pts)\n" % [i + 1, c.car_name, tag, c.training_level, c.top_speed_kmh, cup_points.get(c.car_id, 0)]
		hud_leaderboard.text = text

	if show_telemetry_panel:
		update_telemetry_panel()

extends Node3D
class_name SimulationManager3D

const MaxHeap = preload("res://scripts/MaxHeap.gd")

enum MatchState {
	MENU,          # Pantalla de inicio para elegir modo y equipo rival
	COUNTDOWN,     # Semáforo de salida (3.. 2.. 1.. ¡GO!)
	RACING,        # Carrera activa
	RESULTS        # Pantalla de resultados finales y podio
}

enum GameMode {
	CUP_PLAYER,    # Modo Copa: Tú (Humano) compites contra 9 Redes Neuronales
	SPECTATOR_AI   # Modo Espectador: Solo Redes Neuronales con cámara libre
}

@export var car_scene: PackedScene = preload("res://scenes/Car3D.tscn")
@export var default_car_count: int = 10
@export var laps_to_win: int = 2

var match_state: MatchState = MatchState.MENU
var current_game_mode: GameMode = GameMode.CUP_PLAYER
var current_car_count: int = 10
var cup_round: int = 1
var generation: int = 1
var round_timer: float = 0.0
var max_round_time: float = 90.0 # Segundos máximos antes de dar bandera a cuadros

var cars: Array[Car3D] = []
var cup_points: Dictionary = {}
var focused_car_idx: int = 0

# Semáforo de salida
var countdown_time: float = 3.6
var traffic_light_step: int = -1

# Equipos de IA pre-entrenados y guardados
var available_teams: Array[Dictionary] = []
var selected_team_idx: int = 1 # Por defecto: Escudería GT Pro
var current_team_name: String = "Escudería GT Pro"

var toast_message: String = ""
var toast_timer: float = 0.0
var show_telemetry_panel: bool = false
var show_debug_overlays: bool = false

var car_colors = [
	Color(1.0, 0.85, 0.1),    # 1: Amarillo Dorado (Jugador)
	Color(0.95, 0.2, 0.2),    # 2: Rojo Ferrari
	Color(0.15, 0.55, 1.0),   # 3: Azul Eléctrico
	Color(0.2, 0.85, 0.3),    # 4: Verde Lima
	Color(1.0, 0.5, 0.1),     # 5: Naranja Neón
	Color(0.7, 0.2, 0.9),     # 6: Púrpura
	Color(0.1, 0.85, 0.85),   # 7: Turquesa
	Color(0.95, 0.95, 0.95),  # 8: Blanco Perla
	Color(0.95, 0.3, 0.6),    # 9: Rosa Deportivo
	Color(0.6, 0.8, 0.2)      # 10: Pistacho
]

# Referencias a nodos
@onready var track: Track3D = $Track3D
@onready var camera_rig: CameraRig3D = $CameraRig3D

# Nodos de Interfaz (HUD)
@onready var hud_main_menu: PanelContainer = $CanvasLayer/HUD/MainMenuPanel
@onready var hud_traffic_light: PanelContainer = $CanvasLayer/HUD/TrafficLightPanel
@onready var light_1: ColorRect = $CanvasLayer/HUD/TrafficLightPanel/VBox/LightsHBox/Light1
@onready var light_2: ColorRect = $CanvasLayer/HUD/TrafficLightPanel/VBox/LightsHBox/Light2
@onready var light_3: ColorRect = $CanvasLayer/HUD/TrafficLightPanel/VBox/LightsHBox/Light3
@onready var light_label: Label = $CanvasLayer/HUD/TrafficLightPanel/VBox/CountdownLabel

@onready var hud_results_panel: PanelContainer = $CanvasLayer/HUD/ResultsPanel
@onready var results_title: Label = $CanvasLayer/HUD/ResultsPanel/VBox/TitleLabel
@onready var results_subtitle: Label = $CanvasLayer/HUD/ResultsPanel/VBox/SubtitleLabel
@onready var results_table: RichTextLabel = $CanvasLayer/HUD/ResultsPanel/VBox/Scroll/TableText

@onready var hud_left_panel: PanelContainer = $CanvasLayer/HUD/LeftPanel
@onready var hud_right_panel: PanelContainer = $CanvasLayer/HUD/RightPanel
@onready var hud_bottom_panel: PanelContainer = $CanvasLayer/HUD/BottomPanel
@onready var hud_help_panel: PanelContainer = $CanvasLayer/HUD/HelpPanel
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

# Botones del Menú Principal
@onready var btn_cup_mode: Button = $CanvasLayer/HUD/MainMenuPanel/VBox/ModesHBox/BtnCupMode
@onready var btn_spectator_mode: Button = $CanvasLayer/HUD/MainMenuPanel/VBox/ModesHBox/BtnSpectator
@onready var btn_team_select: OptionButton = $CanvasLayer/HUD/MainMenuPanel/VBox/TeamHBox/TeamOptionBtn
@onready var btn_start_race: Button = $CanvasLayer/HUD/MainMenuPanel/VBox/BtnStartRace
@onready var btn_quit_game: Button = $CanvasLayer/HUD/MainMenuPanel/VBox/BtnQuitGame

# Botones de la Pantalla de Resultados
@onready var btn_next_round: Button = $CanvasLayer/HUD/ResultsPanel/VBox/ButtonsHBox/BtnNextRound
@onready var btn_retry_race: Button = $CanvasLayer/HUD/ResultsPanel/VBox/ButtonsHBox/BtnRetryRace
@onready var btn_menu_return: Button = $CanvasLayer/HUD/ResultsPanel/VBox/ButtonsHBox/BtnReturnMenu
@onready var btn_quit_results: Button = $CanvasLayer/HUD/ResultsPanel/VBox/ButtonsHBox/BtnQuitResults

var time_scales = [1.0, 2.0, 4.0]
var time_scale_idx = 0

func _ready():
	load_all_teams_catalog()
	setup_menu_ui()
	spawn_race_grid(default_car_count)
	switch_to_menu_state()

func load_all_teams_catalog():
	available_teams.clear()

	# Equipos de fábrica
	var default_paths = [
		{"name": "🔰 Escudería Novatos (Aprendizaje)", "path": "res://saved_teams/Escuderia_Novatos.json", "tier": 0},
		{"name": "🏎️ Escudería GT Pro (Curvas Rápidas)", "path": "res://saved_teams/Escuderia_GT_Pro.json", "tier": 1},
		{"name": "👑 Escudería Élite (Campeones)", "path": "res://saved_teams/Escuderia_Elite_Leyendas.json", "tier": 2}
	]

	for item in default_paths:
		if FileAccess.file_exists(item["path"]):
			available_teams.append(item)
		else:
			available_teams.append({"name": item["name"], "path": "", "tier": item["tier"]})

	# Equipos guardados por el usuario
	var user_dir = "user://saved_teams"
	if DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(user_dir)):
		var dir = DirAccess.open(user_dir)
		if dir:
			dir.list_dir_begin()
			var fn = dir.get_next()
			while fn != "":
				if not dir.current_is_dir() and fn.ends_with(".json"):
					available_teams.append({
						"name": "📂 Guardado: " + fn.get_basename(),
						"path": user_dir + "/" + fn,
						"tier": 3
					})
				fn = dir.get_next()
			dir.list_dir_end()

func setup_menu_ui():
	# Conectar botones del menú
	if btn_cup_mode and not btn_cup_mode.pressed.is_connected(_on_btn_cup_mode_pressed):
		btn_cup_mode.pressed.connect(_on_btn_cup_mode_pressed)
	if btn_spectator_mode and not btn_spectator_mode.pressed.is_connected(_on_btn_spectator_mode_pressed):
		btn_spectator_mode.pressed.connect(_on_btn_spectator_mode_pressed)
	if btn_start_race and not btn_start_race.pressed.is_connected(_on_btn_start_race_pressed):
		btn_start_race.pressed.connect(_on_btn_start_race_pressed)
	if btn_quit_game and not btn_quit_game.pressed.is_connected(_on_btn_quit_pressed):
		btn_quit_game.pressed.connect(_on_btn_quit_pressed)

	# Llenar dropdown de equipos
	if btn_team_select:
		btn_team_select.clear()
		for i in range(available_teams.size()):
			btn_team_select.add_item(available_teams[i]["name"], i)
		btn_team_select.select(1)
		if not btn_team_select.item_selected.is_connected(_on_team_selected):
			btn_team_select.item_selected.connect(_on_team_selected)

	# Conectar botones de resultados
	if btn_next_round and not btn_next_round.pressed.is_connected(advance_to_next_cup_round):
		btn_next_round.pressed.connect(advance_to_next_cup_round)
	if btn_retry_race and not btn_retry_race.pressed.is_connected(retry_current_race):
		btn_retry_race.pressed.connect(retry_current_race)
	if btn_menu_return and not btn_menu_return.pressed.is_connected(switch_to_menu_state):
		btn_menu_return.pressed.connect(switch_to_menu_state)
	if btn_quit_results and not btn_quit_results.pressed.is_connected(_on_btn_quit_pressed):
		btn_quit_results.pressed.connect(_on_btn_quit_pressed)

func _on_btn_quit_pressed():
	get_tree().quit()

func toggle_fullscreen():
	var mode = DisplayServer.window_get_mode()
	if mode == DisplayServer.WINDOW_MODE_FULLSCREEN or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		show_toast("🪟 Modo Ventana activado [F11 para pantalla completa]")
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		show_toast("🖥️ Pantalla Completa activada [F11 para ventana]")

func _on_btn_cup_mode_pressed():
	current_game_mode = GameMode.CUP_PLAYER
	btn_cup_mode.modulate = Color(1.0, 0.9, 0.2)
	btn_spectator_mode.modulate = Color(0.7, 0.7, 0.7)

func _on_btn_spectator_mode_pressed():
	current_game_mode = GameMode.SPECTATOR_AI
	btn_spectator_mode.modulate = Color(0.3, 0.8, 1.0)
	btn_cup_mode.modulate = Color(0.7, 0.7, 0.7)

func _on_team_selected(index: int):
	selected_team_idx = index
	current_team_name = available_teams[index]["name"]

func _on_btn_start_race_pressed():
	start_race_countdown()

# -------------------------------------------------------------
# Transiciones de Estados de Carrera
# -------------------------------------------------------------

func switch_to_menu_state():
	match_state = MatchState.MENU
	Engine.time_scale = 1.0

	# Mostrar menú principal y ocultar HUD de carrera
	hud_main_menu.visible = true
	hud_traffic_light.visible = false
	hud_results_panel.visible = false
	hud_left_panel.visible = false
	hud_right_panel.visible = false
	hud_bottom_panel.visible = false
	hud_help_panel.visible = false
	hud_mode_banner.get_parent().visible = false

	# Cámara en vista panorámica rotatoria lenta
	camera_rig.current_mode = CameraRig3D.CameraMode.OVERVIEW_ISOMETRIC
	camera_rig.is_player_driving = false
	camera_rig.pan_target = Vector3(0, 0, 0)
	camera_rig.zoom_distance = 95.0

	freeze_all_cars(true)

func start_race_countdown():
	match_state = MatchState.COUNTDOWN
	hud_main_menu.visible = false
	hud_results_panel.visible = false

	# Mostrar HUD de carrera y Semáforo
	hud_traffic_light.visible = true
	hud_left_panel.visible = true
	hud_right_panel.visible = true
	hud_bottom_panel.visible = true
	hud_help_panel.visible = true
	hud_mode_banner.get_parent().visible = true

	# Cargar equipo de IA seleccionado y reiniciar en parrilla
	apply_selected_team(selected_team_idx)
	apply_game_mode_to_cars()

	# Configurar semáforo y congelar autos
	countdown_time = 3.6
	traffic_light_step = -1
	update_traffic_light_visuals(0)
	freeze_all_cars(true)

	round_timer = 0.0

func _process(delta: float):
	# Si estamos en menú, rotar suavemente la vista para un fondo 3D dinámico
	if match_state == MatchState.MENU:
		camera_rig.pan_target = Vector3(sin(Time.get_ticks_msec() * 0.0003) * 30.0, 0, cos(Time.get_ticks_msec() * 0.0003) * 20.0)
		return

	# Semáforo de salida
	if match_state == MatchState.COUNTDOWN:
		process_traffic_light(delta)
		return

	# Carrera activa
	if match_state == MatchState.RACING:
		round_timer += delta

		# Comprobar ganador por vueltas
		check_race_finish_conditions()

		var alive_count = 0
		for car in cars:
			if car.is_alive: alive_count += 1

		update_hud(alive_count)

		if alive_count == 0 or round_timer >= max_round_time:
			show_race_results()

	# Temporizador para avisos flotantes (Toast)
	if toast_timer > 0.0:
		toast_timer -= delta
		if toast_timer <= 0.0 and hud_toast_label:
			hud_toast_label.get_parent().visible = false

func process_traffic_light(delta: float):
	countdown_time -= delta

	if countdown_time > 2.0:
		if traffic_light_step != 1:
			traffic_light_step = 1
			update_traffic_light_visuals(1)
	elif countdown_time > 1.0:
		if traffic_light_step != 2:
			traffic_light_step = 2
			update_traffic_light_visuals(2)
	elif countdown_time > 0.0:
		if traffic_light_step != 3:
			traffic_light_step = 3
			update_traffic_light_visuals(3)
	else:
		if traffic_light_step != 4:
			traffic_light_step = 4
			update_traffic_light_visuals(4)
			# ¡¡SALIDA / GO!! Descongelar vehículos
			freeze_all_cars(false)
			match_state = MatchState.RACING
			show_toast("🚦 ¡¡BANDERAZO DE SALIDA!! ¡ACELERA!")

	if countdown_time <= -1.2:
		hud_traffic_light.visible = false

func update_traffic_light_visuals(step: int):
	var dark_color = Color(0.15, 0.15, 0.15)
	var red_color = Color(1.0, 0.1, 0.1)
	var green_color = Color(0.1, 1.0, 0.2)

	match step:
		0:
			light_1.color = dark_color
			light_2.color = dark_color
			light_3.color = dark_color
			light_label.text = "¡PREPARADOS!"
			light_label.modulate = Color.WHITE
		1:
			light_1.color = red_color
			light_2.color = dark_color
			light_3.color = dark_color
			light_label.text = "3"
			light_label.modulate = red_color
		2:
			light_1.color = red_color
			light_2.color = red_color
			light_3.color = dark_color
			light_label.text = "2"
			light_label.modulate = red_color
		3:
			light_1.color = red_color
			light_2.color = red_color
			light_3.color = red_color
			light_label.text = "1"
			light_label.modulate = red_color
		4:
			light_1.color = green_color
			light_2.color = green_color
			light_3.color = green_color
			light_label.text = "¡¡GO!!"
			light_label.modulate = green_color

func check_race_finish_conditions():
	for car in cars:
		if car.current_lap >= laps_to_win:
			show_race_results()
			return

func show_race_results():
	match_state = MatchState.RESULTS
	freeze_all_cars(true)
	hud_results_panel.visible = true

	# Clasificar autos mediante Max-Heap (Cola de Prioridad O(k log N))
	var rank_heap = MaxHeap.new()
	for car in cars:
		rank_heap.push(car, car.fitness)
	var sorted_cars: Array = rank_heap.get_top_k(cars.size())

	var winner = sorted_cars[0]
	var player_car = get_player_car()
	var player_pos = sorted_cars.find(player_car) + 1

	if current_game_mode == GameMode.CUP_PLAYER:
		if player_pos == 1:
			results_title.text = "🏆 ¡¡VICTORIA ÉPICA!! ¡ERES EL CAMPEÓN!"
			results_title.modulate = Color(1.0, 0.85, 0.2)
			results_subtitle.text = "¡Has derrotado a todas las Redes Neuronales en la Ronda %d!" % cup_round
		elif player_pos in [2, 3]:
			results_title.text = "🥈 ¡PODIO CONSEGUIDO! (Posición %dº)" % player_pos
			results_title.modulate = Color(0.85, 0.88, 0.95)
			results_subtitle.text = "Excelente carrera contra la %s." % current_team_name
		elif player_car and not player_car.is_alive:
			results_title.text = "💥 VEHÍCULO DESTRUIDO"
			results_title.modulate = Color(1.0, 0.3, 0.3)
			results_subtitle.text = "Tu energía llegó a cero. Intenta evitar impactos excesivos."
		else:
			results_title.text = "🏁 CARRERA FINALIZADA (Posición %dº)" % player_pos
			results_title.modulate = Color(0.9, 0.9, 0.9)
			results_subtitle.text = "Buen esfuerzo en la Ronda %d de la Copa." % cup_round
	else:
		results_title.text = "🏁 GANADOR: %s" % winner.car_name
		results_title.modulate = winner.car_color
		results_subtitle.text = "Mejor red neuronal de la Generación %d." % generation

	# Asignar puntos de Copa (25, 18, 15, 12, 10...)
	var pts_table = [25, 18, 15, 12, 10, 8, 6, 4, 2, 1]
	for i in range(min(sorted_cars.size(), pts_table.size())):
		var cid = sorted_cars[i].car_id
		cup_points[cid] = cup_points.get(cid, 0) + pts_table[i]

	# Tabla de clasificación
	var table_text = "[table=6]"
	table_text += "[cell][b]Pos[/b][/cell][cell][b]Piloto[/b][/cell][cell][b]Vueltas[/b][/cell][cell][b]Vel. Punta[/b][/cell][cell][b]Salud[/b][/cell][cell][b]Puntos[/b][/cell]"

	for i in range(sorted_cars.size()):
		var c = sorted_cars[i]
		var tag = " [color=yellow](TÚ)[/color]" if c.is_player else ""
		var status = ("%.0f%%" % c.health) if c.is_alive else "[color=red]DEAD[/color]"
		var pts = cup_points.get(c.car_id, 0)
		table_text += "[cell]%dº[/cell][cell]%s%s[/cell][cell]%d[/cell][cell]%.0f km/h[/cell][cell]%s[/cell][cell]%d pts[/cell]" % [
			i + 1, c.car_name, tag, c.current_lap, c.top_speed_kmh, status, pts
		]
	table_text += "[/table]"
	results_table.text = table_text

func advance_to_next_cup_round():
	cup_round += 1
	generation += 1

	# Selección Elitista Óptima en O(k log N) con Max-Heap
	var num_elites = max(2, int(cars.size() * 0.25))
	var elite_heap = MaxHeap.new()
	for car in cars:
		elite_heap.push(car, car.fitness)
	var elite_cars: Array = elite_heap.get_top_k(num_elites)

	var new_brains: Array[GodotBrain] = []
	for i in range(num_elites):
		var elite = GodotBrain.new()
		elite.set_weights(elite_cars[i].brain.get_weights())
		new_brains.append(elite)

	while new_brains.size() < cars.size():
		var pA = new_brains[randi() % num_elites]
		var pB = new_brains[randi() % num_elites]
		var child = pA.crossover(pB)
		child.mutate(0.10, 0.20)
		new_brains.append(child)

	var grid_transforms = track.get_starting_grid_transforms(cars.size())
	for i in range(cars.size()):
		cars[i].brain = new_brains[i]
		cars[i].reset_car(grid_transforms[i])

	start_race_countdown()
	show_toast("🏆 ¡Avanzando a Ronda %d de la Copa! Rivales IA evolucionados con C++." % cup_round)

func retry_current_race():
	var grid_transforms = track.get_starting_grid_transforms(cars.size())
	for i in range(cars.size()):
		cars[i].reset_car(grid_transforms[i])
	start_race_countdown()

# -------------------------------------------------------------
# Gestión de Autos y Modos
# -------------------------------------------------------------

func apply_game_mode_to_cars():
	if cars.is_empty():
		return

	if current_game_mode == GameMode.CUP_PLAYER:
		cars[0].is_player = true
		cars[0].car_name = "TÚ (Jugador 1)"
		cars[0].set_car_color(Color(1.0, 0.85, 0.1)) # Dorado
		focused_car_idx = 0
		camera_rig.current_mode = CameraRig3D.CameraMode.GTA_TOPDOWN
		camera_rig.is_player_driving = true
		camera_rig.focus_on_car(cars[0])
	else:
		cars[0].is_player = false
		cars[0].car_name = "Auto #1 (IA)"
		camera_rig.current_mode = CameraRig3D.CameraMode.OVERVIEW_ISOMETRIC
		camera_rig.is_player_driving = false
		camera_rig.focus_on_car(cars[focused_car_idx])

func freeze_all_cars(freeze: bool):
	for car in cars:
		car.is_frozen = freeze
		if freeze:
			car.speed = 0.0
			car.velocity = Vector3.ZERO

func apply_selected_team(idx: int):
	if idx < 0 or idx >= available_teams.size():
		return

	var team_info = available_teams[idx]
	current_team_name = team_info["name"]
	var file_path = team_info["path"]

	if file_path != "" and FileAccess.file_exists(file_path):
		var file = FileAccess.open(file_path, FileAccess.READ)
		var text = file.get_as_text()
		file.close()

		var data = JSON.parse_string(text)
		if data and data.has("cars"):
			var car_list = data["cars"]
			for i in range(min(cars.size(), car_list.size())):
				var c_data = car_list[i]
				var w_array: Array = c_data.get("weights", [])
				var packed_w = PackedFloat32Array()
				for w in w_array:
					packed_w.append(float(w))
				cars[i].brain.set_weights(packed_w)
				if not cars[i].is_player and c_data.has("name"):
					cars[i].car_name = c_data["name"]
	else:
		# Generar en caliente según tier
		var tier = team_info.get("tier", 1)
		for car in cars:
			if tier == 0:
				car.brain.randomize(-1.0, 1.0)
			elif tier == 1:
				car.brain.initialize_heuristic()
				car.brain.mutate(0.08, 0.12)
			elif tier == 2:
				car.brain.initialize_heuristic()
				car.brain.mutate(0.03, 0.06)

	var grid_transforms = track.get_starting_grid_transforms(cars.size())
	for i in range(cars.size()):
		cars[i].reset_car(grid_transforms[i])

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
		car.set_car_color(car_colors[i % car_colors.size()])

		car.brain = GodotBrain.new()
		car.brain.initialize_heuristic()

		car.reset_car(grid_transforms[i])
		car.set_debug_rays_visible(show_debug_overlays)
		cars.append(car)
		cup_points[car.car_id] = 0

	focused_car_idx = 0
	update_camera_target()

func get_player_car() -> Car3D:
	for c in cars:
		if c.is_player: return c
	return null

func get_focused_car() -> Car3D:
	if focused_car_idx >= 0 and focused_car_idx < cars.size():
		return cars[focused_car_idx]
	return null

func cycle_focused_car(direction: int):
	if cars.is_empty(): return
	focused_car_idx = (focused_car_idx + direction + cars.size()) % cars.size()
	update_camera_target()
	update_hud()

func update_camera_target():
	var car = get_focused_car()
	if car and camera_rig:
		camera_rig.focus_on_car(car)

# -------------------------------------------------------------
# Guardado de Generaciones y Reinicio Completo
# -------------------------------------------------------------

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
		for w in car.brain.get_weights():
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
		load_all_teams_catalog()
		setup_menu_ui()
		show_toast("💾 ¡Generación guardada con éxito!: %s" % filename)
	else:
		show_toast("❌ Error al guardar el archivo.")

func reset_entire_simulation():
	round_timer = 0.0
	cup_round = 1
	generation = 1
	cup_points.clear()

	var grid_transforms = track.get_starting_grid_transforms(cars.size())
	for i in range(cars.size()):
		cars[i].reset_car(grid_transforms[i])
		cup_points[cars[i].car_id] = 0

	apply_selected_team(selected_team_idx)
	apply_game_mode_to_cars()
	start_race_countdown()
	show_toast("🔄 ¡SIMULACIÓN REINICIADA! (Ronda 1, Gen 1, Puntos a 0)")

# -------------------------------------------------------------
# HUD y Atajos de Teclado
# -------------------------------------------------------------

func _unhandled_input(event: InputEvent):
	if not (event is InputEventKey) or not event.is_pressed() or event.is_echo():
		return

	var key = (event as InputEventKey).keycode

	# Escape: Volver al Menú Principal o Salir del juego si ya está en el menú
	if key == KEY_ESCAPE:
		if match_state != MatchState.MENU:
			switch_to_menu_state()
		else:
			get_tree().quit()
		return

	# F11: Pantalla completa / Ventana
	elif key == KEY_F11:
		toggle_fullscreen()

	# Q: Visualizar u ocultar las divisiones del Árbol Espacial (SpatialTree3D) y sensores de los autos
	elif key == KEY_Q:
		if track:
			show_debug_overlays = track.toggle_spatial_tree_debug()
			for car in cars:
				car.set_debug_rays_visible(show_debug_overlays)
			show_toast("🔲 Divisiones 3D y Sensores: " + ("ACTIVADOS (Cuadrantes + Rayos de sensores)" if show_debug_overlays else "DESACTIVADAS") + " [Tecla Q]")

	# TAB: Alternar entre MODO JUGADOR y ESPECTADOR
	if key == KEY_TAB:
		if current_game_mode == GameMode.CUP_PLAYER:
			current_game_mode = GameMode.SPECTATOR_AI
		else:
			current_game_mode = GameMode.CUP_PLAYER
		apply_game_mode_to_cars()
		update_hud()

	# F5 o Shift + R: Reiniciar todo desde cero
	elif key == KEY_F5 or (key == KEY_R and event.shift_pressed):
		reset_entire_simulation()

	# R (sin Shift): Forzar siguiente carrera / Fin de ronda
	elif key == KEY_R and match_state == MatchState.RACING:
		show_race_results()

	# G: Guardar generación
	elif key == KEY_G:
		save_current_generation()

	# I: Telemetría detallada
	elif key == KEY_I:
		toggle_telemetry_window()

	# C: Cambiar auto enfocado
	elif key == KEY_C:
		if event.shift_pressed:
			cycle_focused_car(-1)
		else:
			cycle_focused_car(1)

	# V: Alternar perspectiva de cámara
	elif key == KEY_V:
		camera_rig.cycle_camera_mode()
		update_hud()

	# Espacio: Velocidad de simulación
	elif key == KEY_SPACE:
		time_scale_idx = (time_scale_idx + 1) % time_scales.size()
		Engine.time_scale = time_scales[time_scale_idx]
		update_hud()

func toggle_telemetry_window():
	show_telemetry_panel = not show_telemetry_panel
	if hud_telemetry_window:
		hud_telemetry_window.visible = show_telemetry_panel
		if show_telemetry_panel:
			update_telemetry_panel()

func update_telemetry_panel():
	if not hud_telemetry_text: return
	var text = "[b]📊 TELEMETRÍA Y NIVEL DE ENTRENAMIENTO:[/b]\n"
	text += "Ronda: %d | Gen: %d | Equipo rival: [color=yellow]%s[/color]\n\n" % [cup_round, generation, current_team_name]
	text += "[table=7]"
	text += "[cell][b]Auto[/b][/cell][cell][b]Nivel[/b][/cell][cell][b]Vel. Punta[/b][/cell][cell][b]Vueltas[/b][/cell][cell][b]Mejor Vuelta[/b][/cell][cell][b]Salud[/b][/cell][cell][b]Puntos[/b][/cell]"

	# Clasificación eficiente con Max-Heap en O(k log N)
	var heap = MaxHeap.new()
	for car in cars:
		heap.push(car, car.fitness)
	var sorted: Array = heap.get_top_k(cars.size())

	for c in sorted:
		var name_str = c.car_name + (" (TÚ)" if c.is_player else "")
		var level_str = "⭐ Nv.%d" % c.training_level
		var speed_str = "%.0f km/h" % c.top_speed_kmh
		var laps_str = "%d/%d" % [c.current_lap, laps_to_win]
		var lap_time_str = ("%.2fs" % c.best_lap_time) if c.best_lap_time < 900.0 else "--"
		var hp_str = ("%.0f%%" % c.health) if c.is_alive else "[color=red]DEAD[/color]"
		var pts_str = "%d pts" % cup_points.get(c.car_id, 0)
		text += "[cell]%s[/cell][cell]%s[/cell][cell]%s[/cell][cell]%s[/cell][cell]%s[/cell][cell]%s[/cell][cell]%s[/cell]" % [
			name_str, level_str, speed_str, laps_str, lap_time_str, hp_str, pts_str
		]
	text += "[/table]\n"

	# Estadísticas de Estructuras de Datos Avanzadas (Programación 3 - Kerwin Quintero)
	if track and track.spatial_tree:
		var metrics = track.spatial_tree.get_metrics_summary()
		text += "\n[b]🌳 ESTRUCTURAS DE DATOS Y OPTIMIZACIÓN (Programación 3):[/b]\n"
		text += "• [color=cyan]SpatialTree3D[/color]: Nodos=%d | Consultas=%d | Ramas podadas=%d [O(log N)]\n" % [
			metrics["total_nodes"], metrics["total_queries"], metrics["pruned_branches"]
		]
		text += "• [color=green]Max-Heap[/color]: Montículo binario activo para selección de élite y ranking [O(k log N)]\n"
		text += "• [color=yellow]Sensores Optimizados[/color]: Evaluación por distancia al cuadrado (d²) sin sqrt redundante\n"

	text += "\n[color=gray]Pulsa [I] para cerrar.[/color]"
	hud_telemetry_text.text = text

func show_toast(msg: String):
	toast_message = msg
	toast_timer = 4.0
	if hud_toast_label:
		hud_toast_label.text = msg
		hud_toast_label.get_parent().visible = true

func update_hud(alive_count: int = -1):
	if alive_count == -1:
		alive_count = 0
		for c in cars:
			if c.is_alive: alive_count += 1

	if hud_mode_banner:
		if current_game_mode == GameMode.CUP_PLAYER:
			hud_mode_banner.text = "🏆 MODO COPA: Tú vs IAs (WASD para conducir)  |  [ESC]: Menú Principal"
			hud_mode_banner.modulate = Color(1.0, 0.9, 0.2)
		else:
			hud_mode_banner.text = "👁️ MODO ESPECTADOR: Isométrica Libre (Arrastra ratón / Scroll)  |  [TAB]: Conducir"
			hud_mode_banner.modulate = Color(0.4, 0.85, 1.0)

	if hud_round_label:
		hud_round_label.text = "🏆 Copa - Ronda %d | Gen %d" % [cup_round, generation]
	if hud_alive_label:
		hud_alive_label.text = "🏎️ En Pista: %d / %d" % [alive_count, cars.size()]
	if hud_speed_label:
		hud_speed_label.text = "⚡ Velocidad: %.0fx [Espacio]" % Engine.time_scale
	if hud_team_label:
		hud_team_label.text = "🤖 Rival: %s" % current_team_name

	var focused = get_focused_car()
	if focused:
		if hud_car_name:
			hud_car_name.text = "🎯 %s" % focused.car_name
			hud_car_name.modulate = focused.car_color
		if hud_car_mode:
			if focused.is_player:
				hud_car_mode.text = "🎮 [TÚ: WASD o Flechas]"
				hud_car_mode.modulate = Color(0.3, 1.0, 0.4)
			else:
				hud_car_mode.text = "🧠 [RED NEURONAL C++]"
				hud_car_mode.modulate = Color(0.4, 0.7, 1.0)
		if hud_car_hp_bar:
			hud_car_hp_bar.value = focused.health
			if focused.is_in_grass:
				hud_car_speed.text = "⚠️ ¡FUERA DE PISTA! Daño continuo en pasto..."
			else:
				hud_car_speed.text = "Velocidad: %.0f km/h | Vuelta: %d/%d" % [abs(focused.speed * 3.6), focused.current_lap, laps_to_win]
		if hud_cam_mode:
			hud_cam_mode.text = "%s [Tecla V]" % camera_rig.get_mode_name()

	if hud_leaderboard:
		var sorted_cars = cars.duplicate()
		sorted_cars.sort_custom(func(a, b): return a.fitness > b.fitness)
		var text = "🏁 POSICIONES EN VIVO:\n"
		for i in range(min(5, sorted_cars.size())):
			var c = sorted_cars[i]
			var status = "%.0f%% HP" % c.health if c.is_alive else "DEAD"
			var tag = " (TÚ)" if c.is_player else ""
			text += "%dº %s%s (V.%d, %d pts)\n" % [i + 1, c.car_name, tag, c.current_lap, cup_points.get(c.car_id, 0)]
		hud_leaderboard.text = text

	if show_telemetry_panel:
		update_telemetry_panel()

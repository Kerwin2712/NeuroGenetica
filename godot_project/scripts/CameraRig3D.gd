extends Camera3D
class_name CameraRig3D

enum CameraMode {
	OVERVIEW_ISOMETRIC,   # Vista isométrica general libre con ratón y scroll
	GTA_TOPDOWN,          # Vista cenital desde arriba estilo GTA clásico
	ISOMETRIC_FOLLOW,     # Vista isométrica fija siguiendo al auto enfocado
	CHASE_CAM             # Vista persecución en 3ª persona detrás del auto
}

@export var current_mode: CameraMode = CameraMode.OVERVIEW_ISOMETRIC
@export var smooth_speed: float = 8.0

var target_car: Car3D = null

# Controles de la Vista Isométrica Libre
var pan_target: Vector3 = Vector3(0, 0, 0)
var zoom_distance: float = 75.0
var is_panning: bool = false
var is_player_driving: bool = false

func _ready():
	# Iniciar centrado en la pista
	pan_target = Vector3(0, 0, 0)

func _unhandled_input(event: InputEvent):
	if current_mode == CameraMode.OVERVIEW_ISOMETRIC:
		if event is InputEventMouseButton:
			var mb = event as InputEventMouseButton
			if mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.is_pressed():
				# Zoom In con rueda del ratón
				zoom_distance = max(22.0, zoom_distance - 7.0)
			elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.is_pressed():
				# Zoom Out con rueda del ratón
				zoom_distance = min(160.0, zoom_distance + 7.0)
			elif mb.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT, MOUSE_BUTTON_MIDDLE]:
				is_panning = mb.is_pressed()

		elif event is InputEventMouseMotion and is_panning:
			var mm = event as InputEventMouseMotion
			# Arrastre isométrico con el ratón
			var factor = (zoom_distance / 80.0) * 0.28
			var move_x = -mm.relative.x * factor
			var move_z = -mm.relative.y * factor
			pan_target += Vector3(move_x - move_z, 0, move_x + move_z)

func _process(delta: float):
	match current_mode:
		CameraMode.OVERVIEW_ISOMETRIC:
			update_overview_isometric(delta)
		CameraMode.GTA_TOPDOWN:
			update_gta_topdown(delta)
		CameraMode.ISOMETRIC_FOLLOW:
			update_isometric_follow(delta)
		CameraMode.CHASE_CAM:
			update_chase_cam(delta)

func update_overview_isometric(delta: float):
	# Si no se está conduciendo activamente un auto, permitir desplazamiento con teclado
	if not is_player_driving:
		var pan_dir = Vector3.ZERO
		if Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_W): pan_dir += Vector3(-1, 0, -1)
		if Input.is_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_S): pan_dir += Vector3(1, 0, 1)
		if Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A): pan_dir += Vector3(-1, 0, 1)
		if Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D): pan_dir += Vector3(1, 0, -1)

		if pan_dir != Vector3.ZERO:
			pan_target += pan_dir.normalized() * 50.0 * delta

	# Posición isométrica pura a 45°
	var iso_vector = Vector3(1.0, 1.25, 1.0).normalized() * zoom_distance
	var desired_pos = pan_target + iso_vector
	global_position = global_position.lerp(desired_pos, smooth_speed * delta)

	var cur_trans = global_transform.looking_at(pan_target, Vector3.UP)
	global_transform = global_transform.interpolate_with(cur_trans, smooth_speed * delta)

func update_gta_topdown(delta: float):
	if target_car == null or not is_instance_valid(target_car):
		return

	# Altura cenital de 25m directamente sobre el auto enfocado
	var target_pos = target_car.global_position + Vector3(0, 25.0, 0)
	global_position = global_position.lerp(target_pos, smooth_speed * delta)

	# Orientar con el rumbo del auto para conducir "hacia arriba" (estilo GTA 1/2)
	var car_yaw = target_car.rotation.y
	var current_yaw = rotation.y
	var target_rot_y = lerp_angle(current_yaw, car_yaw, smooth_speed * delta)

	rotation = Vector3(-deg_to_rad(85.0), target_rot_y, 0.0)

func update_isometric_follow(delta: float):
	if target_car == null or not is_instance_valid(target_car):
		return

	var offset = Vector3(18.0, 22.0, 18.0)
	var target_pos = target_car.global_position + offset
	global_position = global_position.lerp(target_pos, smooth_speed * delta)

	var look_target = target_car.global_position + Vector3(0, 0.5, 0)
	var cur_trans = global_transform.looking_at(look_target, Vector3.UP)
	global_transform = global_transform.interpolate_with(cur_trans, smooth_speed * delta)

func update_chase_cam(delta: float):
	if target_car == null or not is_instance_valid(target_car):
		return

	var forward = -target_car.global_transform.basis.z
	var target_pos = target_car.global_position - forward * 8.5 + Vector3(0, 3.6, 0)
	global_position = global_position.lerp(target_pos, smooth_speed * 1.5 * delta)

	var look_target = target_car.global_position + forward * 10.0 + Vector3(0, 1.2, 0)
	var cur_trans = global_transform.looking_at(look_target, Vector3.UP)
	global_transform = global_transform.interpolate_with(cur_trans, smooth_speed * 1.5 * delta)

func cycle_camera_mode():
	var next = (int(current_mode) + 1) % 4
	current_mode = next as CameraMode
	# Si cambia a isométrica general, centrarla cerca del auto enfocado
	if current_mode == CameraMode.OVERVIEW_ISOMETRIC and target_car:
		pan_target = target_car.global_position

func focus_on_car(car: Car3D):
	target_car = car
	if current_mode == CameraMode.OVERVIEW_ISOMETRIC and car:
		pan_target = car.global_position

func get_mode_name() -> String:
	match current_mode:
		CameraMode.OVERVIEW_ISOMETRIC:
			return "📐 Isométrica Libre (Arrastra ratón / Scroll zoom)"
		CameraMode.GTA_TOPDOWN:
			return "🎮 Vista GTA Cenital (Top-Down)"
		CameraMode.ISOMETRIC_FOLLOW:
			return "🎯 Isométrica Siguiendo Auto"
		CameraMode.CHASE_CAM:
			return "🏎️ Vista Tercera Persona (Chase)"
	return ""

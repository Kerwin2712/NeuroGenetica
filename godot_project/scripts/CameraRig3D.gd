extends Camera3D
class_name CameraRig3D

enum CameraMode {
	GTA_TOPDOWN,          # Vista cenital desde arriba estilo GTA clásico
	ISOMETRIC_FOLLOW,     # Vista isométrica siguiendo al auto enfocado
	CHASE_CAM,            # Vista persecución en 3ª persona detrás del auto
	OVERVIEW_ISOMETRIC    # Vista isométrica panorámica general de todo el circuito
}

@export var current_mode: CameraMode = CameraMode.GTA_TOPDOWN
@export var smooth_speed: float = 7.0

var target_car: Car3D = null
var overview_center: Vector3 = Vector3(0, 0, 0)

func _process(delta: float):
	match current_mode:
		CameraMode.GTA_TOPDOWN:
			update_gta_topdown(delta)
		CameraMode.ISOMETRIC_FOLLOW:
			update_isometric_follow(delta)
		CameraMode.CHASE_CAM:
			update_chase_cam(delta)
		CameraMode.OVERVIEW_ISOMETRIC:
			update_overview_isometric(delta)

func update_gta_topdown(delta: float):
	if target_car == null or not is_instance_valid(target_car):
		return

	# Altura cenital de 26m
	var target_pos = target_car.global_position + Vector3(0, 26.0, 0)
	global_position = global_position.lerp(target_pos, smooth_speed * delta)

	# Orientar suavemente con la rotación del auto para conducir "hacia arriba" (estilo GTA 1/2)
	var car_yaw = target_car.rotation.y
	var current_yaw = rotation.y
	var target_rot_y = lerp_angle(current_yaw, car_yaw, smooth_speed * delta)
	
	rotation = Vector3(-deg_to_rad(85.0), target_rot_y, 0.0)

func update_isometric_follow(delta: float):
	if target_car == null or not is_instance_valid(target_car):
		return

	# Ángulo isométrico clásico (45° en horizontal y vertical)
	var offset = Vector3(18.0, 22.0, 18.0)
	var target_pos = target_car.global_position + offset
	global_position = global_position.lerp(target_pos, smooth_speed * delta)

	# Mirar al vehículo
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

func update_overview_isometric(delta: float):
	var overview_pos = overview_center + Vector3(65.0, 95.0, 65.0)
	global_position = global_position.lerp(overview_pos, smooth_speed * 0.5 * delta)

	var cur_trans = global_transform.looking_at(overview_center, Vector3.UP)
	global_transform = global_transform.interpolate_with(cur_trans, smooth_speed * 0.5 * delta)

func cycle_camera_mode():
	var next = (int(current_mode) + 1) % 4
	current_mode = next as CameraMode

func get_mode_name() -> String:
	match current_mode:
		CameraMode.GTA_TOPDOWN:
			return "🎮 Vista GTA Cenital (Top-Down)"
		CameraMode.ISOMETRIC_FOLLOW:
			return "📐 Vista Isométrica de Coche"
		CameraMode.CHASE_CAM:
			return "🏎️ Vista Tercera Persona (Chase)"
		CameraMode.OVERVIEW_ISOMETRIC:
			return "🌐 Vista Panorámica General"
	return ""

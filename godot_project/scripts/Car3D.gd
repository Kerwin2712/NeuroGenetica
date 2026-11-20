extends CharacterBody3D
class_name Car3D

# Identificación y configuración
@export var car_id: int = 1
@export var car_name: String = "Auto #1"
@export var car_color: Color = Color(0.2, 0.65, 1.0)
@export var is_player: bool = false

# Cerebro C++ (GDExtension)
var brain: GodotBrain

# Estado físico
var speed: float = 0.0
var max_speed: float = 38.0        # ~136 km/h en escala 3D
var max_reverse: float = 12.0
var acceleration: float = 24.0
var braking_power: float = 35.0
var friction: float = 10.0
var steer_speed: float = 2.4

# Salud / Resistencia / Energía
var max_health: float = 100.0
var health: float = 100.0
var is_alive: bool = true
var is_frozen: bool = false
var is_in_grass: bool = false
var track_ref: Track3D = null


# Rendimiento y Carrera
var fitness: float = 0.0
var distance_traveled: float = 0.0
var current_lap: int = 0
var current_checkpoint: int = 0
var checkpoints_passed: int = 0
var current_lap_time: float = 0.0
var best_lap_time: float = 999.0
var top_speed_kmh: float = 0.0
var training_level: int = 1
var race_time: float = 0.0
var total_collisions: int = 0


# Referencias a nodos
@onready var sensors_node: Node3D = $Sensors
@onready var ray_front: RayCast3D = $Sensors/RayFront
@onready var ray_left: RayCast3D = $Sensors/RayLeft
@onready var ray_right: RayCast3D = $Sensors/RayRight
@onready var ray_left_far: RayCast3D = $Sensors/RayLeftFar
@onready var ray_right_far: RayCast3D = $Sensors/RayRightFar
@onready var chassis_mesh: MeshInstance3D = $Chassis
@onready var label_3d: Label3D = $Billboard/Label3D
@onready var smoke_particles: CPUParticles3D = $SmokeParticles

var sensor_rays: Array[RayCast3D] = []
var sensor_debug_instance: MeshInstance3D = null
var sensor_debug_mesh: ImmediateMesh = null
var chassis_material: StandardMaterial3D
var flash_timer: float = 0.0
var debug_show_rays: bool = false

func _ready():
	if brain == null:
		brain = GodotBrain.new()

	sensor_rays = [ray_left_far, ray_left, ray_front, ray_right, ray_right_far]
	_setup_sensor_debug_mesh()

	# Configurar material único para el chasis
	chassis_material = StandardMaterial3D.new()
	chassis_material.albedo_color = car_color
	chassis_material.roughness = 0.3
	chassis_material.metallic = 0.6
	chassis_mesh.material_override = chassis_material

	update_label()

func _setup_sensor_debug_mesh():
	sensor_debug_mesh = ImmediateMesh.new()
	sensor_debug_instance = MeshInstance3D.new()
	sensor_debug_instance.name = "SensorDebugRays"
	sensor_debug_instance.mesh = sensor_debug_mesh
	sensor_debug_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	sensor_debug_instance.visible = debug_show_rays

	var mat = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	sensor_debug_instance.material_override = mat

	if sensors_node:
		sensors_node.add_child(sensor_debug_instance)
	else:
		add_child(sensor_debug_instance)

func set_debug_rays_visible(enabled: bool):
	debug_show_rays = enabled
	if sensor_debug_instance:
		sensor_debug_instance.visible = enabled and is_alive
		if enabled and is_alive:
			update_debug_rays_mesh()
		else:
			sensor_debug_mesh.clear_surfaces()

func update_debug_rays_mesh():
	if not sensor_debug_mesh or not sensors_node:
		return
	sensor_debug_mesh.clear_surfaces()
	if not debug_show_rays or not is_alive:
		return

	const ORIGIN := Vector3(0.0, 0.15, 0.0)
	const NEAR_SQ: float = 10.5 * 10.5   # < 30% de 35m -> rojo
	const MID_SQ: float = 22.75 * 22.75  # < 65% de 35m -> amarillo
	const CROSS_SIZE: float = 0.45

	sensor_debug_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	for ray in sensor_rays:
		if not is_instance_valid(ray):
			continue
		var end_local: Vector3
		var line_color: Color
		var did_hit: bool = ray.is_colliding()

		if did_hit:
			var hit_global = ray.get_collision_point()
			end_local = sensors_node.to_local(hit_global)
			end_local.y = ORIGIN.y
			var dist_sq = (hit_global - ray.global_position).length_squared()
			if dist_sq < NEAR_SQ:
				line_color = Color(1.0, 0.18, 0.18, 0.95)  # Peligro cercano
			elif dist_sq < MID_SQ:
				line_color = Color(1.0, 0.8, 0.12, 0.92)   # Distancia media
			else:
				line_color = Color(0.25, 1.0, 0.45, 0.85)  # Obstáculo lejano
		else:
			end_local = ray.target_position
			end_local.y = ORIGIN.y
			line_color = Color(0.15, 0.92, 0.65, 0.55)     # Camino despejado

		sensor_debug_mesh.surface_set_color(line_color)
		sensor_debug_mesh.surface_add_vertex(ORIGIN)
		sensor_debug_mesh.surface_set_color(line_color)
		sensor_debug_mesh.surface_add_vertex(end_local)

		# Pequeña cruz 3D en el punto exacto de impacto del sensor
		if did_hit:
			var hit_color = Color(1.0, 0.95, 0.95, 1.0)
			sensor_debug_mesh.surface_set_color(hit_color)
			sensor_debug_mesh.surface_add_vertex(end_local + Vector3(-CROSS_SIZE, 0, 0))
			sensor_debug_mesh.surface_set_color(hit_color)
			sensor_debug_mesh.surface_add_vertex(end_local + Vector3(CROSS_SIZE, 0, 0))

			sensor_debug_mesh.surface_set_color(hit_color)
			sensor_debug_mesh.surface_add_vertex(end_local + Vector3(0, -CROSS_SIZE, 0))
			sensor_debug_mesh.surface_set_color(hit_color)
			sensor_debug_mesh.surface_add_vertex(end_local + Vector3(0, CROSS_SIZE, 0))

			sensor_debug_mesh.surface_set_color(hit_color)
			sensor_debug_mesh.surface_add_vertex(end_local + Vector3(0, 0, -CROSS_SIZE))
			sensor_debug_mesh.surface_set_color(hit_color)
			sensor_debug_mesh.surface_add_vertex(end_local + Vector3(0, 0, CROSS_SIZE))
	sensor_debug_mesh.surface_end()

func _physics_process(delta: float):
	if is_frozen:
		speed = 0.0
		velocity = Vector3.ZERO
		if debug_show_rays and is_alive:
			update_debug_rays_mesh()
		return

	if not is_alive:
		# Auto destruido: desacelerar hasta detenerse
		speed = move_toward(speed, 0.0, friction * 2.0 * delta)
		velocity = -global_transform.basis.z * speed
		velocity.y -= 9.8 * delta
		move_and_slide()
		return

	race_time += delta

	# Efecto visual de parpadeo tras recibir daño
	if flash_timer > 0.0:
		flash_timer -= delta
		if flash_timer <= 0.0:
			chassis_material.albedo_color = car_color

	# 1. Obtener entradas de conducción (Humano o Red Neuronal C++)
	var steer_input: float = 0.0
	var throttle_input: float = 0.0

	if is_player:
		# Conducción manual con teclado: soporte universal Flechas y WASD
		var steer: float = 0.0
		if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
			steer += 1.0
		if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
			steer -= 1.0
		steer_input = steer

		var throttle: float = 0.0
		if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
			throttle += 1.0
		if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
			throttle -= 1.0
		throttle_input = throttle
	else:
		# Conducción autónoma con Red Neuronal
		var inputs = read_sensors()
		var outputs: PackedFloat32Array = brain.predict(inputs)
		if outputs.size() >= 2:
			steer_input = clamp(outputs[0], -1.0, 1.0)
			throttle_input = clamp(outputs[1], -1.0, 1.0)

	# 2. Dinámica vehicular 3D
	rotate_y(steer_input * steer_speed * delta)

	if throttle_input > 0.0:
		speed = min(speed + throttle_input * acceleration * delta, max_speed)
	elif throttle_input < 0.0:
		if speed > 0.5:
			# Frenado
			speed = max(speed + throttle_input * braking_power * delta, 0.0)
		else:
			# Marcha atrás
			speed = max(speed + throttle_input * acceleration * 0.5 * delta, -max_reverse)
	else:
		# Resistencia y fricción natural
		speed = move_toward(speed, 0.0, friction * delta)

	# Movimiento en plano horizontal asegurando que no caiga bajo el suelo
	var forward = -global_transform.basis.z
	velocity = forward * speed
	velocity.y = 0.0
	move_and_slide()

	# Garantizar plano de altura Y estricto y orientación vertical correcta
	if global_position.y < 0.2:
		global_position.y = 0.25
	rotation.x = 0.0
	rotation.z = 0.0

	# 3. Detección y penalización por salirse de la pista al pasto
	if track_ref:
		var on_track = track_ref.is_on_track(global_position)
		if not on_track:
			is_in_grass = true
			# Drena energía continuamente mientras esté fuera del asfalto
			take_damage(26.0 * delta)
			# Fricción extrema del pasto que frena el auto
			speed = move_toward(speed, 0.0, 22.0 * delta)
		else:
			is_in_grass = false

	# 4. Cálculo de colisiones y daño por impacto
	process_collisions()

	# 5. Registro de telemetría y paso por Checkpoints
	current_lap_time += delta
	var current_kmh = abs(speed * 3.6)
	if current_kmh > top_speed_kmh:
		top_speed_kmh = current_kmh

	if track_ref and track_ref.checkpoints.size() > 0:
		var target_idx = (current_checkpoint + 1) % track_ref.checkpoints.size()
		var target_pos = track_ref.checkpoints[target_idx]
		# Optimización: Comparación por distancia euclidiana al cuadrado (evita sqrt innecesario)
		var check_radius = track_ref.track_width * 0.75
		if global_position.distance_squared_to(target_pos) < (check_radius * check_radius):
			current_checkpoint = target_idx
			checkpoints_passed += 1
			if current_checkpoint == 0:
				current_lap += 1
				if current_lap_time < best_lap_time:
					best_lap_time = current_lap_time
				current_lap_time = 0.0

	# 6. Actualizar métricas de rendimiento (Fitness y Nivel de Entrenamiento)
	distance_traveled += speed * delta
	fitness = distance_traveled + (current_lap * 3000.0) + (checkpoints_passed * 120.0) + (health * 1.5) - (total_collisions * 12.0)
	training_level = clamp(1 + int(fitness / 400.0), 1, 10)

	# Estancamiento: si tras 6s no avanza casi nada, pierde energía
	if race_time > 6.0 and distance_traveled < 15.0:
		take_damage(20.0 * delta)

	if debug_show_rays:
		update_debug_rays_mesh()

	update_label()


# Lectura optimizada de sensores de distancia
# - Multiplicación por inverso para evitar divisiones repetidas en el pipeline gráfico
# - Comprobación por distancia al cuadrado para descarte rápido y reducción de overhead
func read_sensors() -> PackedFloat32Array:
	var inputs = PackedFloat32Array()
	const MAX_RANGE: float = 35.0
	const MAX_RANGE_SQ: float = MAX_RANGE * MAX_RANGE
	const INV_MAX_RANGE: float = 1.0 / MAX_RANGE

	for ray in sensor_rays:
		if ray.is_colliding():
			var hit_pos = ray.get_collision_point()
			var diff = hit_pos - ray.global_position
			var dist_sq = diff.length_squared()
			if dist_sq < MAX_RANGE_SQ:
				var dist = sqrt(dist_sq)
				inputs.append(clamp(dist * INV_MAX_RANGE, 0.0, 1.0))
			else:
				inputs.append(1.0)
		else:
			inputs.append(1.0)

	# Entrada 6: Velocidad actual normalizada
	inputs.append(clamp(speed / max_speed, 0.0, 1.0))
	return inputs

func process_collisions():
	var count = get_slide_collision_count()
	if count == 0:
		return

	for i in range(count):
		var col = get_slide_collision(i)
		var normal = col.get_normal()
		var impact_speed = abs(velocity.dot(normal))

		if impact_speed > 2.0:
			total_collisions += 1
			# Daño proporcional a la violencia del choque
			var damage = (impact_speed * 1.4) + 3.0
			take_damage(damage)

			# Rebote y pérdida de inercia
			speed *= 0.4
			velocity = velocity.bounce(normal) * 0.3

			# Si choca contra otro auto, transmitir daño mutuo
			var other = col.get_collider()
			if other is Car3D and other != self:
				other.take_damage(damage * 0.7)

func take_damage(amount: float):
	if not is_alive:
		return

	health = max(0.0, health - amount)

	# Destello rojo de daño
	if chassis_material:
		chassis_material.albedo_color = Color(1.0, 0.1, 0.1)
		flash_timer = 0.12

	if health <= 0.0:
		die()

func die():
	is_alive = false
	health = 0.0
	speed = 0.0
	if smoke_particles:
		smoke_particles.emitting = true
	if sensor_debug_instance:
		sensor_debug_instance.visible = false
	if chassis_material:
		chassis_material.albedo_color = Color(0.15, 0.15, 0.15)
	update_label()

func reset_car(spawn_transform: Transform3D):
	global_transform = spawn_transform
	speed = 0.0
	velocity = Vector3.ZERO
	health = max_health
	is_alive = true
	distance_traveled = 0.0
	fitness = 0.0
	race_time = 0.0
	current_lap = 0
	current_checkpoint = 0
	checkpoints_passed = 0
	current_lap_time = 0.0
	total_collisions = 0

	if smoke_particles:
		smoke_particles.emitting = false
	if sensor_debug_instance:
		sensor_debug_instance.visible = debug_show_rays
	if chassis_material:
		chassis_material.albedo_color = car_color
	update_label()

func set_car_color(new_color: Color):
	car_color = new_color
	if chassis_material:
		chassis_material.albedo_color = new_color

func update_label():
	if label_3d:
		if is_alive:
			var prefix = "⭐ [TÚ]\n" if is_player else ""
			var grass_warn = " ⚠️[PASTO]" if is_in_grass else ""
			label_3d.text = "%s%s\n[%.0f%% HP]%s %.0f km/h" % [prefix, car_name, health, grass_warn, abs(speed * 3.6)]
			if is_player:
				label_3d.modulate = Color(1.0, 0.9, 0.2)
			elif is_in_grass:
				label_3d.modulate = Color(1.0, 0.3, 0.2)
			elif health > 60.0:
				label_3d.modulate = Color(0.4, 1.0, 0.4)
			elif health > 30.0:
				label_3d.modulate = Color(1.0, 0.9, 0.3)
			else:
				label_3d.modulate = Color(1.0, 0.3, 0.3)
		else:
			label_3d.text = "%s\n[DESTRUIDO]" % car_name
			label_3d.modulate = Color(0.6, 0.6, 0.6)

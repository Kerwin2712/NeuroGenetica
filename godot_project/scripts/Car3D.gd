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
@onready var ray_front: RayCast3D = $Sensors/RayFront
@onready var ray_left: RayCast3D = $Sensors/RayLeft
@onready var ray_right: RayCast3D = $Sensors/RayRight
@onready var ray_left_far: RayCast3D = $Sensors/RayLeftFar
@onready var ray_right_far: RayCast3D = $Sensors/RayRightFar
@onready var chassis_mesh: MeshInstance3D = $Chassis
@onready var label_3d: Label3D = $Billboard/Label3D
@onready var smoke_particles: CPUParticles3D = $SmokeParticles

var chassis_material: StandardMaterial3D
var flash_timer: float = 0.0
var debug_show_rays: bool = false

func _ready():
	if brain == null:
		brain = GodotBrain.new()

	# Configurar material único para el chasis
	chassis_material = StandardMaterial3D.new()
	chassis_material.albedo_color = car_color
	chassis_material.roughness = 0.3
	chassis_material.metallic = 0.6
	chassis_mesh.material_override = chassis_material

	update_label()

func _physics_process(delta: float):
	if is_frozen:
		speed = 0.0
		velocity = Vector3.ZERO
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

	update_label()


# Lectura optimizada de sensores de distancia
# - Multiplicación por inverso para evitar divisiones repetidas en el pipeline gráfico
# - Comprobación por distancia al cuadrado para descarte rápido y reducción de overhead
func read_sensors() -> PackedFloat32Array:
	var inputs = PackedFloat32Array()
	var rays = [ray_left_far, ray_left, ray_front, ray_right, ray_right_far]
	const MAX_RANGE: float = 35.0
	const MAX_RANGE_SQ: float = MAX_RANGE * MAX_RANGE
	const INV_MAX_RANGE: float = 1.0 / MAX_RANGE

	for ray in rays:
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

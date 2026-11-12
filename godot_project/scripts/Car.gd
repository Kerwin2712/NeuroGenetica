extends CharacterBody2D
class_name CarAgent

var brain: GodotBrain
var speed: float = 0.0
var max_speed: float = 380.0
var acceleration: float = 260.0
var friction: float = 80.0
var steer_speed: float = 3.2

var is_alive: bool = true
var fitness: float = 0.0
var distance_traveled: float = 0.0
var time_alive: float = 0.0

# 5 Sensores de visión frontal y lateral
@onready var ray_front: RayCast2D = $RayFront
@onready var ray_left: RayCast2D = $RayLeft
@onready var ray_right: RayCast2D = $RayRight
@onready var ray_left_far: RayCast2D = $RayLeftFar
@onready var ray_right_far: RayCast2D = $RayRightFar

func _ready():
	if brain == null:
		brain = GodotBrain.new()

func _physics_process(delta: float):
	if not is_alive:
		return

	time_alive += delta

	# 1. Lectura normalizada [0.0 - 1.0] de los 5 sensores de distancia
	var inputs = PackedFloat32Array()
	var rays = [ray_left_far, ray_left, ray_front, ray_right, ray_right_far]
	
	for ray in rays:
		if ray.is_colliding():
			var hit_pos = ray.get_collision_point()
			var dist = (hit_pos - global_position).length()
			inputs.append(clamp(dist / 200.0, 0.0, 1.0))
		else:
			inputs.append(1.0)
	
	# Entrada 6: Velocidad actual normalizada
	inputs.append(speed / max_speed)

	# 2. Inferencia ultra-rápida en C++
	var outputs: PackedFloat32Array = brain.predict(inputs)
	var steer_input: float = 0.0
	var throttle_input: float = 0.0

	if outputs.size() >= 2:
		steer_input = clamp(outputs[0], -1.0, 1.0)
		throttle_input = clamp(outputs[1], -1.0, 1.0)

	# 3. Dinámica vehicular
	rotation += steer_input * steer_speed * delta

	if throttle_input > 0.0:
		speed = min(speed + throttle_input * acceleration * delta, max_speed)
	else:
		speed = max(speed - friction * delta, 0.0)

	velocity = -transform.y * speed
	move_and_slide()

	# 4. Cálculo del Fitness
	distance_traveled += speed * delta
	fitness = distance_traveled + (time_alive * 5.0)

	# Descarte por estancamiento (si tras 2.5s no avanza casi nada)
	if time_alive > 2.5 and distance_traveled < 60.0:
		die()

	# 5. Detección de colisión contra bordes de la pista
	if get_slide_collision_count() > 0:
		die()

func die():
	is_alive = false
	speed = 0.0
	velocity = Vector2.ZERO
	# Desvanecer visualmente
	modulate.a = 0.25

func reset(start_pos: Vector2, start_rotation: float):
	global_position = start_pos
	rotation = start_rotation
	speed = 0.0
	velocity = Vector2.ZERO
	is_alive = true
	fitness = 0.0
	distance_traveled = 0.0
	time_alive = 0.0
	modulate.a = 1.0


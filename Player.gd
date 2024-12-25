extends CharacterBody3D

var speed
const WALK_SPEED = 40
const SPRINT_SPEED = 70
const JUMP_VELOCITY = 50
var sensitivity = 0.001
var gravity = 150

const BOB_FREQUENCY = 1.3
const BOB_AMPLIFIER = 0.03
var t_bob = 0.0

const BASE_FOV = 100.0
const MAX_FOV = 110.0
const ZOOM_FOV = 150.0

@onready var head = $Head
@onready var camera1 = $Head/FPP
@onready var camera2 = $Head/TPP
@onready var camera = camera1

@onready var gun_animation = $Head/FPP/mighty_gun/AnimationPlayer
@onready var gun = $Head/FPP/mighty_gun/RayCast3D
@onready var gun_animation1 = $Head/TPP/mighty_gun/AnimationPlayer
@onready var gun1 = $Head/TPP/mighty_gun/RayCast3D
@onready var gun_cam = $Head/FPP/mighty_gun
@onready var gun_cam1 = $Head/TPP/mighty_gun

var bullet = load("res://bullet.tscn")
var instance

func toggle_camera():
	if camera == camera1:
		camera = camera2
	else:
		camera = camera1
	camera.make_current()
	toggle_visibility()

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	camera.make_current()
	toggle_visibility()
	
func _unhandled_input(event):
	if event is InputEventMouseMotion:
		head.rotate_y(-event.relative.x * sensitivity)
		camera.rotate_x(-event.relative.y * sensitivity)
		if camera == camera1:
			camera.rotation_degrees.x = clamp(camera.rotation_degrees.x, -60, 60)
		else:
			camera.rotation_degrees.x = clamp(camera.rotation_degrees.x, -35, 60)

func _physics_process(delta):
	var current_velocity = Vector2(velocity.x, velocity.z).length()
	
	if Input.is_action_pressed("comma") and sensitivity > 0.001:
		sensitivity -= 0.001
	elif Input.is_action_pressed("period") and sensitivity < 0.03:
		sensitivity += 0.001
	
	if Input.is_action_just_pressed("f5"):
		toggle_camera()
	
	if not is_on_floor():
		velocity.y -= gravity * delta

	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	if Input.is_action_pressed("shift") and is_on_floor():
		speed = SPRINT_SPEED
	else:
		speed = WALK_SPEED
	
	var input_dir = Input.get_vector("a", "d", "w", "s")
	var direction = (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if is_on_floor():
		if direction:
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
		else:
			velocity.x = lerp(velocity.x, direction.x * speed, delta * 7.0)
		velocity.z = lerp(velocity.z, direction.z * speed, delta * 7.0)
	else:
		velocity.x = lerp(velocity.x, direction.x * speed, delta * 2.0)
		velocity.z = lerp(velocity.z, direction.z * speed, delta * 2.0)
	
	t_bob += delta * velocity.length() * float(is_on_floor())
	if camera == camera1:
		camera.transform.origin = _headbob(t_bob)
	
	if Input.is_action_pressed("right_mouse"):
		var target_fov = BASE_FOV + (ZOOM_FOV - BASE_FOV) * -1.1
		camera.fov = lerp(camera.fov, target_fov, delta * 8.0)
	else:
		camera.fov = lerp(camera.fov, BASE_FOV, delta * 8.0)
	
	if Input.is_action_pressed("shift") and is_on_floor() and not Input.is_action_pressed("right_mouse"):
		if current_velocity > WALK_SPEED:
			var target_fov = BASE_FOV + (MAX_FOV - BASE_FOV) * ((current_velocity - WALK_SPEED) / (SPRINT_SPEED - WALK_SPEED))
			camera.fov = lerp(camera.fov, target_fov, delta * 8.0)
		else:
			camera.fov = lerp(camera.fov, BASE_FOV, delta * 8.0)
	elif camera == camera1:
		camera.fov = lerp(camera.fov, BASE_FOV, delta * 8.0)
	
	if Input.is_action_pressed("shoot"):
		handle_shooting()

	move_and_slide()
	
func handle_shooting():
	if camera == camera1:
		shoot(gun, gun_animation)
	elif camera == camera2:
		shoot(gun1, gun_animation1)

func shoot(_gun, animation_player):
	_gun.visible = true
	if not animation_player.is_playing():
		animation_player.play("shoot")
		instance_bullet(_gun)

	toggle_visibility()

func instance_bullet(_gun):
	instance = bullet.instantiate()
	instance.global_transform = _gun.global_transform
	get_parent().add_child(instance)

func toggle_visibility():
	gun_cam.visible = camera == camera1
	gun_cam1.visible = camera == camera2

func _headbob(time) -> Vector3:
	var pos = camera.transform.origin
	pos.x = cos(time * BOB_FREQUENCY / 2) * BOB_AMPLIFIER
	return pos

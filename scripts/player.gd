extends CharacterBody3D

@export var move_speed: float = 7.0
@export var acceleration: float = 30.0
@export var friction: float = 35.0
@export var jump_velocity: float = 6.0
@export var gravity: float = 18.0
@export var mouse_sensitivity: float = 0.002

@onready var head: Node3D = $Head
@onready var speed_label: Label = $HUD/SpeedLabel

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	if (
		event is InputEventMouseMotion
		and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
	):
		rotate_y(-event.relative.x * mouse_sensitivity)

		head.rotate_x(-event.relative.y * mouse_sensitivity)
		head.rotation.x = clamp(
			head.rotation.x,
			deg_to_rad(-89.0),
			deg_to_rad(89.0)
		)

	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	if (
		event is InputEventMouseButton
		and event.button_index == MOUSE_BUTTON_LEFT
		and event.pressed
	):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _physics_process(delta: float) -> void:
	apply_gravity(delta)
	handle_jump()
	handle_movement(delta)

	move_and_slide()
	update_speed_label()


func apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta


func handle_jump() -> void:
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

func handle_movement(delta: float) -> void:
	var input_vector := Input.get_vector(
		"move_left",
		"move_right",
		"move_forward",
        "move_backward"
	)

	var local_direction := Vector3(
		input_vector.x,
		0.0,
		input_vector.y
	)

	var direction := transform.basis * local_direction
	direction.y = 0.0
	direction = direction.normalized()

	if direction != Vector3.ZERO:
		velocity.x = move_toward(
			velocity.x,
			direction.x * move_speed,
			acceleration * delta
		)

		velocity.z = move_toward(
			velocity.z,
			direction.z * move_speed,
			acceleration * delta
		)
	else:
		velocity.x = move_toward(
			velocity.x,
			0.0,
			friction * delta
		)

		velocity.z = move_toward(
			velocity.z,
			0.0,
			friction * delta
		)

func update_speed_label() -> void:
	var speed := Vector2(
		velocity.x,
		velocity.z
	).length()
	
	speed_label.text = "SPEED %.1f" % speed

extends CharacterBody3D

# 地上での最大移動速度
@export var move_speed: float = 7.0

# 加速度
@export var acceleration: float = 30.0

# 減速度
@export var friction: float = 35.0

# ジャンプ速度
@export var jump_velocity: float = 6.0

# 重力
@export var gravity: float = 18.0

# マウス感度
@export var mouse_sensitivity: float = 0.002

# ストレイフの感度
@export var air_acceleration: float = 18.0

# 空中での加速上限
@export var air_speed_cap: float = 3.0

# スライドを開始できる最低速度
@export var slide_min_speed: float = 6

# スライド中の減速度
@export var slide_friction: float = 4.0

# スライドを終了する速度
@export var slide_end_speed: float = 0.5

# 立ってるときの視点高さ
@export var stand_head_h: float = 0.65

# スライド、しゃがみ中の視点高さ
@export var slide_head_h: float = 0.25

# 視点の高さが切り替わる速度
@export var slide_camera_speed: float = 8.0

# しゃがみ中の移動速度
@export var crouch_speed: float = 3

# しゃがみ状態時の加速度
@export var crouch_acceleration: float = 5.0

# しゃがみ中の減速度
@export var crouch_friction: float = 5.0

# 壁蹴りの強度
@export var wall_kick_speed: float = 7.0

# 壁蹴りの上方向への速度
@export var wall_kick_vertical_speed: float = 6.0

# 着地前に押したジャンプ入力を保持する時間（秒）
@export_range(0.0, 0.2, 0.005)
var jump_buffer_time: float = 0.08
var jump_buffer_timer: float = 0.0

# 同じ壁として扱う法線の類似度
@export_range(-1.0, 1.0, 0.05)
var same_wall_dot_threshold: float = 0.8
var last_wall_normal: Vector3 = Vector3.ZERO

var is_sliding: bool = false
var is_crouching: bool = false
var can_wall_kick: bool = true
var spawn_position: Vector3
var spawn_rotation: Vector3

@onready var head: Node3D = $Head
@onready var standing_collider: CollisionShape3D = $StandingCollider
@onready var crouching_collider: CollisionShape3D = $CrouchingCollider
@onready var ceiling_check: ShapeCast3D = $CeilingCheck
@onready var speed_label: Label = $HUD/SpeedLabel

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	spawn_position = global_position
	spawn_rotation = global_rotation


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
	if Input.is_action_just_pressed("restart"):
		restart_player()
	
	update_jump_buffer(delta)
	
	apply_gravity(delta)
	
	var is_jumped_this_frame := handle_jump()
	handle_movement(delta, is_jumped_this_frame)
	update_collider_state()

	move_and_slide()
	update_speed_label()
	update_slide_camera(delta)


func apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta

func handle_movement(
		delta: float, 
		jumped_this_frame
	) -> void:
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

		update_slide_state()
		
		if jumped_this_frame or not is_on_floor():
			is_sliding = false
			accelerate_air(direction, delta)
			return
		
		if is_sliding:
			apply_slide_friction(delta)
			return
			
		if is_crouching:
			apply_ground_friction(delta, crouch_friction)
			
			if direction != Vector3.ZERO:
				accelerate_ground(
					direction,
					delta,
					crouch_speed,
					crouch_acceleration
				)
			return

		if is_sliding:
			apply_slide_friction(delta)
			return

		apply_ground_friction(delta, friction)

		if direction != Vector3.ZERO:
			accelerate_ground(
				direction,
				delta,
				move_speed,
				acceleration
			)

func accelerate_ground(
	direction: Vector3,
	delta: float,
	target_speed: float,
	acceleration_rate: float
) -> void:
	var current_speed := velocity.dot(direction)
	var speed_to_add := target_speed - current_speed

	if speed_to_add <= 0.0:
		return
	
	var acceleration_speed := (
		acceleration_rate
		* target_speed
		* delta
	)
	
	velocity += direction * min(
		acceleration_speed,
		speed_to_add
	)
	
func apply_ground_friction(
		delta: float,
		friction_rate: float
	) -> void:
		var horizon_velocity := Vector3(
			velocity.x,
			0.0,
			velocity.z
		)
		
		var current_speed := horizon_velocity.length()
		
		if current_speed <= 0.001:
			velocity.x = 0.0
			velocity.z = 0.0
			return
			
		var new_speed := maxf(
			current_speed - friction_rate * delta,
			0.0
		)
			
		var speed_scale := new_speed / current_speed
		
		velocity.x *= speed_scale
		velocity.z *= speed_scale

func handle_jump() -> bool:
	if is_on_floor():
		last_wall_normal = Vector3.ZERO

	if jump_buffer_timer <= 0.0:
		return false

	var wall_normal := find_wall_normal()

	var can_kick_wall := (
		wall_normal != Vector3.ZERO
		and (
			not is_on_floor()
			or is_sliding
		)
		and is_different_wall(wall_normal)
	)

	if can_kick_wall:
		perform_wall_kick(wall_normal)
		return true

	if is_on_floor():
		velocity.y = jump_velocity
		jump_buffer_timer = 0.0
		return true

	return false

func update_speed_label() -> void:
	var speed := Vector2(
		velocity.x,
		velocity.z
	).length()
	
	var movement_state = ""
	
	if is_sliding:
		movement_state = "    SLIDE"
	elif is_crouching:
		movement_state = "    CROUCH"
	else:
		movement_state = "    RUN"
		
	var can_standing = ""
	
	if can_stand_up():
		can_standing = "    CAN STAND"
	else:
		can_standing = "    CAN'T STAND"
		
	
	speed_label.text = "SPEED %.1f%s%s" % [speed, movement_state, can_standing]
	
func accelerate_air(
	wish_direction: Vector3,
	delta: float
) -> void:
	if wish_direction == Vector3.ZERO:
		return
		
	var speed_now := velocity.dot(wish_direction)
	var speed_add := air_speed_cap - speed_now
	
	if speed_add <= 0.0:
		return
	
	var acceleration_speed := (
		air_acceleration
		* air_speed_cap
		* delta
	)
	
	velocity += wish_direction * min(
		acceleration_speed,
		speed_add
	)

func update_jump_buffer(delta: float) -> void:
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = jump_buffer_time
	else:
		jump_buffer_timer = maxf(
			jump_buffer_timer - delta,
			0.0,
		)

func update_slide_state() -> void:
	var horizontal_speed := Vector2(
		velocity.x,
		velocity.z
	).length()

	# キーを離したら立つ
	if not Input.is_action_pressed("slide"):
		is_sliding = false

		if can_stand_up():
			is_crouching = false
		else:
			is_crouching = true
		return

	# キーを押した瞬間だけスライド開始を判定する
	if Input.is_action_just_pressed("slide"):
		if (
			is_on_floor()
			and horizontal_speed >= slide_min_speed
		):
			is_sliding = true
			is_crouching = false
		else:
			is_sliding = false
			is_crouching = true
		return

	# スライド中に減速したらしゃがみに移行する
	if (
		is_sliding
		and (
			not is_on_floor()
			or horizontal_speed <= slide_end_speed
		)
	):
		is_sliding = false
		is_crouching = true

	# キーを押し続けている間はしゃがみを維持する
	if not is_sliding:
		is_crouching = true

func apply_slide_friction(delta: float) -> void:
	var horizon_velocity := Vector3(
		velocity.x,
		0.0,
		velocity.z
	)
	
	var current_speed := horizon_velocity.length()
	
	if current_speed <= 0.001:
		is_sliding = false
		return
		
	var new_speed = maxf(
		current_speed - slide_friction * delta,
		0.0
	)
	
	var speed_scale: float = new_speed / current_speed
	
	velocity.x *= speed_scale
	velocity.z *= speed_scale

func update_slide_camera(delta: float) -> void:
	var target_height := stand_head_h
	
	if is_sliding or is_crouching:
		target_height = slide_head_h
		
	head.position.y = move_toward(
		head.position.y,
		target_height,
		slide_camera_speed * delta
	)

func can_stand_up() -> bool:
	ceiling_check.force_shapecast_update()
	return not ceiling_check.is_colliding()

func update_collider_state() -> void:
	var should_crouch := is_sliding or is_crouching

	standing_collider.set_deferred(
		"disabled",
		should_crouch
	)

	crouching_collider.set_deferred(
		"disabled",
		not should_crouch
	)

func find_wall_normal() -> Vector3:
	for index in range(get_slide_collision_count()):
		var collision: KinematicCollision3D = get_slide_collision(index)
		var normal: Vector3 = collision.get_normal()

		if absf(normal.y) < 0.7:
			return normal.normalized()

	return Vector3.ZERO

func is_different_wall(wall_normal: Vector3) -> bool:
	if last_wall_normal == Vector3.ZERO:
		return true

	return wall_normal.dot(last_wall_normal) < same_wall_dot_threshold

func perform_wall_kick(wall_normal: Vector3) -> void:
	var away_from_wall := Vector3(
		wall_normal.x,
		0.0,
		wall_normal.z
	).normalized()

	var horizontal_velocity := Vector3(
		velocity.x,
		0.0,
		velocity.z
	)

	var tangent_velocity := horizontal_velocity.slide(
		away_from_wall
	)

	var kicked_velocity := (
		tangent_velocity
		+ away_from_wall * wall_kick_speed
	)

	velocity.x = kicked_velocity.x
	velocity.z = kicked_velocity.z
	velocity.y = wall_kick_vertical_speed

	last_wall_normal = wall_normal
	jump_buffer_timer = 0.0
	is_sliding = false

func restart_player():
	global_position = spawn_position
	global_rotation = spawn_rotation
	velocity = Vector3.ZERO
	
	is_sliding = false
	is_crouching = false
	last_wall_normal = Vector3.ZERO
	jump_buffer_timer = 0.0

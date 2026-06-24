extends Node3D
class_name Weapon

# 武器名
@export var weapon_name: String = "Weapon"

# 1発あたりのダメージ
@export var damage: float = 20.0

# 最大射程
@export var max_range: float = 200.0

# 押し続けたときに連射するか
@export var automatic: bool = true

# 現在この武器を使用できるか
@export var is_active: bool = true

# カメラ中央から飛ばすレイ
@export var shoot_ray: RayCast3D

# 1発ごとの銃の跳ね上がり角度
@export var recoil_pitch: float = 2.0

# 左右へぶれる最大角度
@export var recoil_yaw: float = 0.5

# 銃が手前へ下がる距離
@export var recoil_back: float = 0.05

# 元の位置へ戻る速さ
@export var recoil_recovery: float = 12.0

# 1秒あたりの発射数
@export_range(0.1, 30.0, 0.1)
var fire_rate: float = 10.0

var rest_position: Vector3
var rest_rotation: Vector3
var fire_cooldown: float = 0.0


func _ready() -> void:
	rest_position = position
	rest_rotation = rotation
	
	if shoot_ray == null:
		push_error(
			weapon_name
			+ ": ShootRayが設定されていません"
		)
		return

	shoot_ray.target_position = Vector3(
		0.0,
		0.0,
		-max_range
	)


func _physics_process(delta: float) -> void:
	fire_cooldown = maxf(
		fire_cooldown - delta,
		0.0
	)

	if not is_active:
		return

	var wants_to_fire: bool

	if automatic:
		wants_to_fire = Input.is_action_pressed("fire")
	else:
		wants_to_fire = Input.is_action_just_pressed("fire")

	if wants_to_fire and fire_cooldown <= 0.0:
		fire()
		fire_cooldown = 1.0 / fire_rate
	
	update_recoil(delta)


func fire() -> void:
	apply_recoil()
	
	if shoot_ray == null:
		return

	shoot_ray.target_position = Vector3(
		0.0,
		0.0,
		-max_range
	)

	shoot_ray.force_raycast_update()

	if not shoot_ray.is_colliding():
		print(weapon_name, ": miss")
		return

	var collider: Object = shoot_ray.get_collider()
	var hit_position: Vector3 = (
		shoot_ray.get_collision_point()
	)

	print(
		weapon_name,
		": hit ",
		collider,
		" at ",
		hit_position
	)

	if (
		collider != null
		and collider.has_method("take_damage")
	):
		collider.call("take_damage", damage)

func update_recoil(delta: float) -> void:
	var weight := clampf(
		recoil_recovery * delta,
		0.0,
		1.0
	)

	position = position.lerp(
		rest_position,
		weight
	)

	rotation.x = lerp_angle(
		rotation.x,
		rest_rotation.x,
		weight
	)

	rotation.y = lerp_angle(
		rotation.y,
		rest_rotation.y,
		weight
	)

	rotation.z = lerp_angle(
		rotation.z,
		rest_rotation.z,
		weight
	)

func apply_recoil() -> void:
	position.z += recoil_back

	rotation_degrees.x -= recoil_pitch
	rotation_degrees.y += randf_range(
		-recoil_yaw,
		recoil_yaw
	)

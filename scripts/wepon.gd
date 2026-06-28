extends Node3D
class_name Weapon

## 武器名
@export var weapon_name: String = "Weapon"

## 1発あたりのダメージ
@export var damage: float = 20.0

## 最大射程
@export var max_range: float = 200.0

## 押し続けたときに連射するか
@export var automatic: bool = true

## 現在この武器を使用できるか
@export var is_active: bool = true

## 1発ごとの銃の跳ね上がり角度
@export var recoil_pitch: float = 2.0

## 左右へぶれる最大角度
@export var recoil_yaw: float = 0.5

## 銃が手前へ下がる距離
@export var recoil_back: float = 0.05

## 元の位置へ戻る速さ
@export var recoil_recovery: float = 12.0

## カメラが1発ごとに上へ跳ねる角度
@export var camera_recoil_pitch: float = 0.65

## カメラが左右へぶれる最大角度
@export var camera_recoil_yaw: float = 0.18

## 上方向へ蓄積できる最大反動
@export var camera_recoil_max_pitch: float = 5.0

## 左右へ蓄積できる最大反動
@export var camera_recoil_max_yaw: float = 1.25

## 発射時に反動へ追従する速さ
@export var camera_recoil_kick_speed: float = 30.0

## 射撃停止後に中央へ戻る速さ
@export var camera_recoil_recovery_speed: float = 9.0

## 弾薬数
@export var magazine_size: int = 30

## 最大予備弾数
@export var reserve_ammo_max: int = 120

## リロード時間
@export var reload_time: float = 1.8

## ビューモデルを指定（銃と腕どっちも含む）
@export var viewmodel: Node3D

## Idleアニメーション（ループ有効にしてください）
@export var idle_animation: StringName = &"idle"

## リロードアニメーション（ループ向こうにしてください）
@export var reload_animation: StringName = &"reload"

## 銃口の発光
@export var muzzle_flash: Node3D

## 発砲音
@export var fire_sound: AudioStreamPlayer

## ADS時に動かすノード
@export var ads_root: Node3D

## デフォルトスコープ
@export var default_scope: ScopeAttachment

## 付けれるスコープ
@export var available_scopes: Array[ScopeAttachment] = []

## スコープをつけるNode
@export var scope_socket: Node3D

## 発射順に適用するリコイルパターン
## X: 左右方向。マイナスで左、プラスで右
## Y: 上方向。1.0で基本反動と同じ強さ
@export var recoil_pattern: Array[Vector2] = [
	Vector2(0.00, 1.00),
	Vector2(0.15, 1.00),
	Vector2(0.35, 1.05),
	Vector2(0.55, 1.05),
	Vector2(0.40, 1.00),
	Vector2(0.10, 0.95),
	Vector2(-0.25, 0.95),
	Vector2(-0.55, 0.90),
	Vector2(-0.75, 0.90),
	Vector2(-0.55, 0.85),
	Vector2(-0.20, 0.85),
	Vector2(0.20, 0.85),
	Vector2(0.55, 0.80),
	Vector2(0.75, 0.80),
	Vector2(0.50, 0.80),
	Vector2(0.10, 0.75),
	Vector2(-0.35, 0.75),
	Vector2(-0.65, 0.75),
	Vector2(-0.40, 0.70),
	Vector2(0.00, 0.70)
]

## 射撃を止めてからパターンを先頭へ戻すまでの時間
@export var recoil_pattern_reset_time: float = 0.25

## パターンに加えるランダムな誤差
@export var recoil_pattern_randomness: Vector2 = Vector2(
	0.05,
	0.03
)

## プレイヤーカメラ
var player_camera: Camera3D

## 1秒あたりの発射数
@export_range(0.1, 30.0, 0.1)
var fire_rate: float = 10.0


enum WeaponState {
	IDLE,
	FIRING,
	RELOADING,
	EQUIPPING
}

var rest_position: Vector3
var rest_rotation: Vector3
var fire_cooldown: float = 0.0
var camera_recoil_target: Vector2 = Vector2.ZERO
var camera_recoil_current: Vector2 = Vector2.ZERO
var camera_recoil_node: Node3D
var shoot_ray: RayCast3D
var state: WeaponState = WeaponState.IDLE
var ads_amount: float = 0.0
var is_aiming: bool = false
var ammo_in_magazine: int
var reserve_ammo: int
var animation_player: AnimationPlayer
var hip_transform: Transform3D
var ads_transform: Transform3D
var current_scope: ScopeAttachment
var was_ads_idle_stopped: bool = false
var current_scope_model: Node3D
var recoil_pattern_index: int = 0
var recoil_pattern_reset_timer: float = 0.0

signal ammo_changed(
	ammo_in_magazine: int,
	reserve_ammo: int
)

signal hit_confirmed
signal reload_started
signal reload_finished

func _ready() -> void:
	setup_animation_player()

	if default_scope != null:
		equip_scope(default_scope)
	else:
		push_error(
			"Default Scopeが設定されていません: %s"
			% weapon_name
		)

	if muzzle_flash != null:
		muzzle_flash.visible = false
	
	rest_position = position
	rest_rotation = rotation
	
	ammo_in_magazine = magazine_size
	reserve_ammo = reserve_ammo_max
	
	ammo_changed.emit(
		ammo_in_magazine,
		reserve_ammo
	)
	
	play_idle_animation()

func _physics_process(delta: float) -> void:
	update_camera_recoil(delta)
	update_recoil(delta)
	update_ads(delta)
	update_recoil_pattern_reset(delta)
	
	fire_cooldown = maxf(
		fire_cooldown - delta,
		0.0
	)

func setup(
	ray: RayCast3D,
	recoil_node: Node3D,
	camera: Camera3D
) -> void:
	shoot_ray = ray
	camera_recoil_node = recoil_node
	player_camera = camera
	
	shoot_ray.enabled = true
	shoot_ray.target_position = Vector3(
		0.0,
		0.0,
		-max_range
	)

func try_fire() -> void:
	if not can_fire():
		return

	state = WeaponState.FIRING

	fire()
	fire_cooldown = 1.0 / fire_rate

	state = WeaponState.IDLE

func fire() -> void:
	ammo_in_magazine -= 1
	
	ammo_changed.emit(
		ammo_in_magazine,
		reserve_ammo
	)
	
	var recoil_step := consume_recoil_pattern()
	
	apply_recoil(recoil_step)
	apply_camera_recoil(recoil_step)
	play_fire_effects()
	
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
		collider.call(
			"take_damage",
			damage
		)
	
		hit_confirmed.emit()

func can_fire() -> bool:
	return (
		is_active
		and state == WeaponState.IDLE
		and fire_cooldown <= 0.0
		and ammo_in_magazine > 0
	)

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

func apply_recoil(recoil_step: Vector2) -> void:
	position.z += recoil_back
	
	rotation_degrees.x -= (
		recoil_pitch
		* recoil_step.y
	)
	
	rotation_degrees.y += (
		recoil_yaw
		* recoil_step.x
	)

func update_camera_recoil(delta: float) -> void:
	if camera_recoil_node == null:
		return

	var kick_weight: float = clampf(
		camera_recoil_kick_speed * delta,
		0.0,
		1.0
	)

	var recovery_weight: float = clampf(
		camera_recoil_recovery_speed * delta,
		0.0,
		1.0
	)

	camera_recoil_current = camera_recoil_current.lerp(
		camera_recoil_target,
		kick_weight
	)

	camera_recoil_target = camera_recoil_target.lerp(
		Vector2.ZERO,
		recovery_weight
	)

	camera_recoil_node.rotation_degrees.x = (
		-camera_recoil_current.x
	)

	camera_recoil_node.rotation_degrees.y = (
		camera_recoil_current.y
	)

func apply_camera_recoil(
	recoil_step: Vector2
) -> void:
	var multiplier: float = 1.0
	
	if (
		is_aiming
		and current_scope != null
	):
		multiplier = current_scope.recoil_multiplier
	
	var pitch_amount := (
		camera_recoil_pitch
		* recoil_step.y
		* multiplier
	)
	
	var yaw_amount := (
		camera_recoil_yaw
		* recoil_step.x
		* multiplier
	)
	
	camera_recoil_target.x = minf(
		camera_recoil_target.x + pitch_amount,
		camera_recoil_max_pitch
	)
	
	camera_recoil_target.y = clampf(
		camera_recoil_target.y + yaw_amount,
		-camera_recoil_max_yaw,
		camera_recoil_max_yaw
	)

func play_fire_effects() -> void:
	if muzzle_flash != null:
		muzzle_flash.visible = true

		if muzzle_flash.has_method("play"):
			muzzle_flash.call("play")
		else:
			push_error(
				"MuzzleFlashVFXにplay()がありません: %s"
				% muzzle_flash.get_path()
			)
	else:
		push_warning(
			"マズルフラッシュが設定されていません: %s"
			% weapon_name
		)

	if fire_sound != null:
		fire_sound.pitch_scale = randf_range(
			0.97,
			1.03
		)
		fire_sound.play()
	else:
		push_warning(
			"発砲音が設定されていません。流石にチートです: %s"
			% weapon_name
		)

func try_reload() -> void:
	if not is_active:
		return
	
	if state != WeaponState.IDLE:
		return
	
	if ammo_in_magazine >= magazine_size:
		return
	
	if reserve_ammo <= 0:
		return
	
	state = WeaponState.RELOADING
	reload_started.emit()

	play_reload_animation()

	await get_tree().create_timer(
		reload_time
	).timeout
	
	var needed_ammo: int = (
		magazine_size - ammo_in_magazine
	)
	
	var loaded_ammo: int = mini(
		needed_ammo,
		reserve_ammo
	)
	
	ammo_in_magazine += loaded_ammo
	reserve_ammo -= loaded_ammo
	
	state = WeaponState.IDLE
	
	ammo_changed.emit(
		ammo_in_magazine,
		reserve_ammo
	)
	
	reload_finished.emit()
	play_idle_animation()

func setup_animation_player() -> void:
	if viewmodel == null:
		push_error(
			"ViewModelが設定されていません: %s"
			% weapon_name
		)
		return
	
	animation_player = viewmodel.find_child(
		"AnimationPlayer",
		true,
		false
	) as AnimationPlayer
	
	if animation_player == null:
		push_error(
			"ViewModel内にAnimationPlayerがありません: %s"
			% viewmodel.get_path()
		)

func play_idle_animation() -> void:
	if animation_player == null:
		return

	if not animation_player.has_animation(
		idle_animation
	):
		push_error(
			"idleアニメーションがありません: %s"
			% idle_animation
		)
		return

	animation_player.play(
		idle_animation
	)


func play_reload_animation() -> void:
	if animation_player == null:
		return

	if not animation_player.has_animation(
		reload_animation
	):
		push_error(
			"リロードアニメーションがありません: %s"
			% reload_animation
		)
		return

	var animation: Animation = (
		animation_player.get_animation(
			reload_animation
		)
	)

	var playback_speed: float = (
		animation.length
		/ maxf(reload_time, 0.001)
	)

	animation_player.play(
		reload_animation,
		0.0,
		playback_speed
	)

func setup_ads() -> void:
	if ads_root == null:
		push_error(
			"AdsRootが設定されていません: %s"
			% weapon_name
		)
		return
	
	hip_transform = ads_root.transform
	
	var active_aim_point: Marker3D = get_active_aim_point()
	
	if active_aim_point == null:
		push_error(
			"AimPointが設定されていません: %s"
			% weapon_name
		)
		return
	
	var active_ads_distance: float = get_active_ads_distance()
	
	var aim_from_root: Transform3D = (
		ads_root.global_transform.affine_inverse()
		* active_aim_point.global_transform
	)
	
	var target_transform := Transform3D(
		Basis.IDENTITY,
		Vector3(
			0.0,
			0.0,
			-active_ads_distance
		)
	)
	
	ads_transform = (
		target_transform
		* aim_from_root.affine_inverse()
	)

func update_ads(delta: float) -> void:
	if ads_root == null:
		print("ads_root is null")
		return
	
	ads_amount = move_toward(
		ads_amount,
		1.0 if is_aiming else 0.0,
		get_active_ads_speed() * delta
	)
	
	ads_root.transform = hip_transform.interpolate_with(
		ads_transform,
		ads_amount
	)
	
	if player_camera != null:
		player_camera.fov = lerpf(
			get_active_hip_fov(),
			get_active_ads_fov(),
			ads_amount
		)

func get_active_aim_point() -> Marker3D:
	if current_scope == null:
		return null

	if current_scope.aim_point_path == NodePath(""):
		return null

	var node := get_node_or_null(
		current_scope.aim_point_path
	)

	if node is Marker3D:
		return node

	return null

func stop_idle_animation() -> void:
	if was_ads_idle_stopped:
		return
	
	if animation_player == null:
		return
	
	if animation_player.current_animation != idle_animation:
		return
	
	animation_player.stop()
	was_ads_idle_stopped = true

func resume_idle_animation() -> void:
	if not was_ads_idle_stopped:
		return
	
	if animation_player == null:
		return
	
	play_idle_animation()
	was_ads_idle_stopped = false

func get_active_ads_distance() -> float:
	if current_scope == null:
		return 0.25

	return current_scope.ads_distance


func get_active_ads_speed() -> float:
	if current_scope == null:
		return 10.0
	
	return current_scope.ads_speed

func equip_scope(scope: ScopeAttachment) -> void:
	if scope == null:
		push_error(
			"装着するScopeAttachmentがnullです: %s"
			% weapon_name
		)
		return
	
	current_scope = scope
	
	if current_scope_model != null:
		current_scope_model.queue_free()
		current_scope_model = null
	
	if scope_socket == null:
		push_error(
			"ScopeSocketが設定されていません: %s"
			% weapon_name
		)
		return
	
	if current_scope.scope_scene == null:
		push_warning(
			"ScopeSceneが設定されていません: %s"
			% current_scope.attachment_name
		)
	
		setup_ads()
		return
	
	var instance := current_scope.scope_scene.instantiate()
	
	if not instance is Node3D:
		push_error(
			"ScopeSceneのルートがNode3Dではありません: %s"
			% current_scope.attachment_name
		)
	
		instance.queue_free()
		return
	
	current_scope_model = instance as Node3D
	scope_socket.add_child(current_scope_model)
	
	current_scope_model.transform = Transform3D.IDENTITY
	current_scope_model.visible = true
	
	setup_ads()

	print(
		"スコープを装着しました: ",
		current_scope.attachment_name,
		" socket=",
		scope_socket.get_path(),
		" model=",
		current_scope_model.get_path()
	)

func get_active_hip_fov() -> float:
	if current_scope == null:
		return 75.0
	
	return current_scope.hip_fov


func get_active_ads_fov() -> float:
	if current_scope == null:
		return 55.0
	
	return current_scope.ads_fov

func update_recoil_pattern_reset(delta: float) -> void:
	if recoil_pattern_index == 0:
		return
	
	recoil_pattern_reset_timer = maxf(
		recoil_pattern_reset_timer - delta,
		0.0
	)
	
	if recoil_pattern_reset_timer <= 0.0:
		recoil_pattern_index = 0

func consume_recoil_pattern() -> Vector2:
	var recoil_step := Vector2(
		0.0,
		1.0
	)
	
	if not recoil_pattern.is_empty():
		var index := mini(
			recoil_pattern_index,
			recoil_pattern.size() - 1
		)
	
		recoil_step = recoil_pattern[index]
	
	recoil_pattern_index += 1
	recoil_pattern_reset_timer = recoil_pattern_reset_time
	
	recoil_step.x += randf_range(
		-recoil_pattern_randomness.x,
		recoil_pattern_randomness.x
	)
	
	recoil_step.y += randf_range(
		-recoil_pattern_randomness.y,
		recoil_pattern_randomness.y
	)
	
	return recoil_step

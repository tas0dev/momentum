extends Node3D
class_name WeaponSystem

@export var starting_weapon: PackedScene
@export var camera_recoil_node: Node3D

@onready var viewmodel_socket: Node3D = %ViewModelSocket
@onready var shoot_ray: RayCast3D = %ShootRay

var current_weapon: Weapon


func _ready() -> void:
	if starting_weapon != null:
		equip(starting_weapon)


func _physics_process(_delta: float) -> void:
	if current_weapon == null:
		return

	var wants_to_fire: bool

	if current_weapon.automatic:
		wants_to_fire = Input.is_action_pressed("fire")
	else:
		wants_to_fire = Input.is_action_just_pressed("fire")

	if wants_to_fire:
		current_weapon.try_fire()


func equip(weapon_scene: PackedScene) -> void:
	if weapon_scene == null:
		return

	if current_weapon != null:
		current_weapon.queue_free()
		current_weapon = null

	var instance := weapon_scene.instantiate()

	if not instance is Weapon:
		push_error(
			"Weaponを継承していないシーンです: %s"
			% weapon_scene.resource_path
		)
		instance.queue_free()
		return

	current_weapon = instance as Weapon
	viewmodel_socket.add_child(current_weapon)

	current_weapon.setup(
		shoot_ray,
		camera_recoil_node
	)

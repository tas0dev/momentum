extends Node3D

var world_camera: Camera3D
var viewmodel_camera: Camera3D
var source_sun: DirectionalLight3D

@onready var viewmodel_sun: DirectionalLight3D = $ViewModelLight


func _ready() -> void:
	viewmodel_camera = get_viewport().get_camera_3d()

	find_scene_nodes()

	viewmodel_sun.sky_mode = (
		DirectionalLight3D.SKY_MODE_LIGHT_ONLY
	)


func _process(_delta: float) -> void:
	if (
		not is_instance_valid(world_camera)
		or not is_instance_valid(source_sun)
		or not is_instance_valid(viewmodel_camera)
	):
		viewmodel_camera = get_viewport().get_camera_3d()
		find_scene_nodes()
		return
	
	sync_sun()

func find_scene_nodes() -> void:
	world_camera = get_tree().get_first_node_in_group(
		"world_camera"
	) as Camera3D

	source_sun = null

	for node in get_tree().get_nodes_in_group("world_sun"):
		if (
			node is DirectionalLight3D
			and node != viewmodel_sun
		):
			source_sun = node
			break

func find_source_sun() -> void:
	source_sun = null

	for node in get_tree().get_nodes_in_group("world_sun"):
		if (
			node is DirectionalLight3D
			and node != viewmodel_sun
		):
			source_sun = node
			break

	if source_sun == null:
		push_error(
			"ワールド側のDirectionalLight3Dが"
			+ "見つかりません"
		)


func sync_sun() -> void:
	var source_basis := (
		source_sun.global_basis.orthonormalized()
	)

	var world_camera_basis := (
		world_camera.global_basis.orthonormalized()
	)

	var viewmodel_camera_basis := (
		viewmodel_camera.global_basis.orthonormalized()
	)

	viewmodel_sun.global_basis = (
		viewmodel_camera_basis
		* world_camera_basis.inverse()
		* source_basis
	).orthonormalized()

	viewmodel_sun.light_color = source_sun.light_color
	viewmodel_sun.light_energy = source_sun.light_energy
	viewmodel_sun.light_specular = source_sun.light_specular
	viewmodel_sun.light_temperature = (
		source_sun.light_temperature
	)
	viewmodel_sun.shadow_enabled = (
		source_sun.shadow_enabled
	)
	viewmodel_sun.visible = source_sun.visible

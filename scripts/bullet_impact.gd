extends Node3D
class_name BulletImpact

## 弾痕が消えるまでの秒数
@export var lifetime: float = 15.0

## 弾痕の最小サイズ倍率
@export var minimum_scale: float = 0.85

## 弾痕の最大サイズ倍率
@export var maximum_scale: float = 1.15

## 壁から少し浮かせる距離
@export var surface_offset: float = 0.002


func setup(
	hit_position: Vector3,
	hit_normal: Vector3
) -> void:
	var normal := hit_normal.normalized()

	global_position = (
		hit_position
		+ normal * surface_offset
	)

	var reference_axis := Vector3.UP

	if absf(normal.dot(reference_axis)) > 0.98:
		reference_axis = Vector3.RIGHT

	var x_axis := (
		reference_axis
		.cross(normal)
		.normalized()
	)

	var z_axis := (
		x_axis
		.cross(normal)
		.normalized()
	)
	
	global_basis = Basis(
		x_axis,
		normal,
		z_axis
	)
	
	rotate_object_local(
		Vector3.UP,
		randf_range(0.0, TAU)
	)

	var scale_multiplier := randf_range(
		minimum_scale,
		maximum_scale
	)

	scale = Vector3.ONE * scale_multiplier

	await get_tree().create_timer(
		lifetime
	).timeout

	queue_free()

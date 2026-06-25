extends Node3D
class_name BulletTracer

@export var lifetime: float = 0.06

@onready var mesh: MeshInstance3D = $Mesh


func setup(
	from_position: Vector3,
	to_position: Vector3
) -> void:
	var offset := to_position - from_position
	var distance := offset.length()
	
	if distance <= 0.001:
		queue_free()
		return
	
	global_position = from_position.lerp(
		to_position,
		0.5
	)
	
	var direction := offset.normalized()
	var up_direction := Vector3.UP
	
	if absf(direction.dot(Vector3.UP)) > 0.98:
		up_direction = Vector3.FORWARD
	
	look_at(
		to_position,
		up_direction
	)
	
	var box := mesh.mesh as BoxMesh
	
	if box == null:
		push_error("トレーサーのMeshがBoxMeshではありません")
		queue_free()
		return
	
	box.size = Vector3(
		0.015,
		0.015,
		distance
	)
	
	await get_tree().create_timer(lifetime).timeout
	queue_free()

extends Area3D

## テレポート先
@export var destination: Marker3D

## テレポート前の速度を維持するか
@export var preserve_velocity: bool = true

## 出口で即座に再テレポートしないための時間
@export var teleport_lock_time: float = 0.15


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	if not body is CharacterBody3D:
		return

	if destination == null:
		return

	if body.has_meta("teleport_locked"):
		return

	body.set_meta("teleport_locked", true)
	teleport_character.call_deferred(body)


func teleport_character(character: CharacterBody3D) -> void:
	if not is_instance_valid(character):
		return

	var entrance_basis: Basis = (
		global_transform.basis.orthonormalized()
	)

	var exit_basis: Basis = (
		destination.global_transform.basis.orthonormalized()
	)

	var local_velocity: Vector3 = (
		entrance_basis.inverse()
		* character.velocity
	)

	character.global_transform = Transform3D(
		exit_basis,
		destination.global_position
	)

	if preserve_velocity:
		character.velocity = exit_basis * local_velocity
	else:
		character.velocity = Vector3.ZERO

	await get_tree().create_timer(
		teleport_lock_time
	).timeout

	if is_instance_valid(character):
		character.remove_meta("teleport_locked")

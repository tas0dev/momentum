extends StaticBody3D
class_name DummyBot

@export var max_health: float = 100.0
@export var respawn_time: float = 2.0

@onready var mesh: MeshInstance3D = $Mesh
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var health_label: Label3D = $HealthLabel

var health: float
var is_dead: bool = false


func _ready() -> void:
	health = max_health
	update_health_label()


func take_damage(amount: float) -> void:
	if is_dead:
		return

	health = maxf(
		health - amount,
		0.0
	)

	print(
		"DummyBot damage: ",
		amount,
		" health: ",
		health
	)

	update_health_label()

	if health <= 0.0:
		die()


func update_health_label() -> void:
	health_label.text = str(
		ceili(health)
	)


func die() -> void:
	is_dead = true

	mesh.visible = false
	health_label.visible = false

	collision_shape.set_deferred(
		"disabled",
		true
	)

	await get_tree().create_timer(
		respawn_time
	).timeout

	respawn()


func respawn() -> void:
	health = max_health
	is_dead = false

	mesh.visible = true
	health_label.visible = true

	collision_shape.set_deferred(
		"disabled",
		false
	)

	update_health_label()

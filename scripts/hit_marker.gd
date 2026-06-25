extends Control

@export var display_time: float = 0.08
@export var fade_time: float = 0.12

var hit_tween: Tween


func _ready() -> void:
	visible = false
	modulate.a = 0.0
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	$Line1.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$Line2.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$Line3.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$Line4.mouse_filter = Control.MOUSE_FILTER_IGNORE


func show_hit() -> void:
	if hit_tween != null:
		hit_tween.kill()

	visible = true
	modulate.a = 1.0
	scale = Vector2(1.15, 1.15)

	hit_tween = create_tween()
	hit_tween.set_parallel(true)

	hit_tween.tween_property(
		self,
		"scale",
		Vector2.ONE,
		display_time
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	hit_tween.tween_property(
		self,
		"modulate:a",
		0.0,
		fade_time
	).set_delay(display_time)

	hit_tween.chain().tween_callback(
		func() -> void:
			visible = false
			scale = Vector2.ONE
	)

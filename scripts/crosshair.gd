extends Control

@export var crosshair_thickness: float = 2.0
@export var crosshair_length: float = 13.0
@export var crosshair_gap: float = 5.0

@onready var crosshair_top: Control = $Top
@onready var crosshair_bottom: Control = $Bottom
@onready var crosshair_right: Control = $Right
@onready var crosshair_left: Control = $Left

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	crosshair_top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	crosshair_bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	crosshair_right.mouse_filter = Control.MOUSE_FILTER_IGNORE
	crosshair_left.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	resized.connect(_update_crosshair)
	_update_crosshair()


func _update_crosshair() -> void:
	var center := size * 0.5
	var half_thickness := crosshair_thickness * 0.5
	
	crosshair_top.size = Vector2(
		crosshair_thickness,
		crosshair_length
	)
	crosshair_top.position = Vector2(
		center.x - half_thickness,
		center.y - crosshair_gap - crosshair_length
	)
	
	crosshair_bottom.size = Vector2(
		crosshair_thickness,
		crosshair_length
	)
	crosshair_bottom.position = Vector2(
		center.x - half_thickness,
		center.y + crosshair_gap
	)
	
	crosshair_left.size = Vector2(
		crosshair_length,
		crosshair_thickness
	)
	crosshair_left.position = Vector2(
		center.x - crosshair_gap - crosshair_length,
		center.y - half_thickness
	)
	
	crosshair_right.size = Vector2(
		crosshair_length,
		crosshair_thickness
	)
	crosshair_right.position = Vector2(
		center.x + crosshair_gap,
		center.y - half_thickness
	)

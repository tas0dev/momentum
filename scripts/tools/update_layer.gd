@tool
extends Node3D

@export_flags_3d_render var visibility_layers: int = 2:
	set(value):
		visibility_layers = value

		if is_inside_tree():
			apply_visibility_layers.call_deferred()


@export_tool_button("レイヤーを適用")
var apply_action: Callable = apply_visibility_layers


func _ready() -> void:
	apply_visibility_layers.call_deferred()


func apply_visibility_layers() -> void:
	if not is_inside_tree():
		return

	apply_to_children(self)


func apply_to_children(node: Node) -> void:
	if node is MeshInstance3D:
		var mesh_instance := node as MeshInstance3D
		mesh_instance.layers = visibility_layers

	for child in node.get_children():
		apply_to_children(child)

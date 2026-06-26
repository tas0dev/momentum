extends Label

@export var weapon_system: WeaponSystem

var connected_weapon: Weapon


func _ready() -> void:
	if weapon_system == null:
		push_error(
			"Ammo HUDにWeaponSystemが設定されていません"
		)
		return

	weapon_system.current_weapon_changed.connect(
		_on_current_weapon_changed
	)

	if weapon_system.current_weapon != null:
		_on_current_weapon_changed(
			weapon_system.current_weapon
		)
	else:
		text = "-- / --"


func _on_current_weapon_changed(
	weapon: Weapon
) -> void:
	if (
		connected_weapon != null
		and is_instance_valid(connected_weapon)
		and connected_weapon.ammo_changed.is_connected(
			_on_ammo_changed
		)
	):
		connected_weapon.ammo_changed.disconnect(
			_on_ammo_changed
		)

	connected_weapon = weapon

	if connected_weapon == null:
		text = "-- / --"
		return

	if not connected_weapon.ammo_changed.is_connected(
		_on_ammo_changed
	):
		connected_weapon.ammo_changed.connect(
			_on_ammo_changed
		)

	_on_ammo_changed(
		connected_weapon.ammo_in_magazine,
		connected_weapon.reserve_ammo
	)


func _on_ammo_changed(
	ammo_in_magazine: int,
	reserve_ammo: int
) -> void:
	text = "%d / %d" % [
		ammo_in_magazine,
		reserve_ammo
	]

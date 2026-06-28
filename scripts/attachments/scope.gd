extends Resource
class_name ScopeAttachment

## アタッチメント名
@export var attachment_name: String = "Iron Sight"

## このスコープでADSしたときに中央へ合わせるMarker3Dのパス
@export var aim_point_path: NodePath

## ADS時にカメラから照準器まで離す距離
@export var ads_distance: float = 0.25

## ADSへ移行する速さ
@export var ads_speed: float = 10.0

## 腰撃ち時のカメラFOV
@export var hip_fov: float = 75.0

## ADS時のカメラFOV
@export var ads_fov: float = 55.0

## ADS時のマウス感度倍率
@export var sensitivity_multiplier: float = 0.65

## ADS時のカメラ反動倍率
@export var recoil_multiplier: float = 1.0

## ADS時のビューモデル揺れ倍率
@export var sway_multiplier: float = 1.0

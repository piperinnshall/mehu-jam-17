extends Resource
class_name MapSettings

@export_category("Map Settings")

@export var width: int = 512
@export var height: int = 512

# Noise settings
@export var base_freq: float = 0.003
@export var base_octaves: int = 4
@export var detail_freq: float = 0.02
@export var detail_octaves: int = 3
@export var detail_gain: float = 0.1

# Terrain thresholds
@export var water_thresh: float = 0.4
@export var sand_thresh: float = 0.42
@export var forest_thresh: float = 0.6

# Colors
@export var water_colors: Array = [Color(0,0,0.2), Color(0,0.1,0.4), Color(0,0.3,0.6)]
@export var sand_colors: Array = [Color(0.9,0.85,0.6), Color(0.95,0.9,0.5), Color(0.8,0.75,0.5)]
@export var land_colors: Array = [Color(0.1,0.4,0.1), Color(0.2,0.5,0.1), Color(0.3,0.6,0.2)]
@export var forest_colors: Array = [Color(0.05,0.3,0.05), Color(0.1,0.5,0.1), Color(0.15,0.6,0.15)]

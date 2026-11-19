class_name SpawnConfig
extends Resource

## Seconds between spawn attempts.
@export var interval: float = 0.5
@export var max_alive: int = 150
## How far outside the visible area enemies appear.
@export var spawn_margin: float = 24.0
@export var enemy_scene: PackedScene
@export var enemy_data: EnemyData

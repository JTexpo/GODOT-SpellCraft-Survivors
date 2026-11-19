class_name SpawnConfig
extends Resource

## Seconds between spawn attempts.
@export var interval: float = 0.5
@export var max_alive: int = 150
## How far outside the visible area enemies appear.
@export var spawn_margin: float = 24.0
@export var enemy_scene: PackedScene
## The enemies the spawner picks from, by each one's spawn_weight.
@export var enemy_pool: Array[EnemyData] = []

class_name EnemyData
extends Resource

@export var max_health: float = 20.0
@export var contact_damage: float = 10.0
## Seconds before this enemy can damage the same target again.
@export var contact_cooldown: float = 1.0
@export var contact_knockback: float = 80.0
@export var speed: float = 40.0
## Random speed spread as a fraction (0.15 means 85% to 115% of speed).
@export var speed_variation: float = 0.15
## Each enemy aims at a random point within this radius of the player, to spread a horde out.
@export var offset_radius: float = 24.0
## The enemy's element: it takes extra damage from the element that beats it and reduced damage
## from the one it beats. None (-1) takes normal damage from everything.
@export_enum("None:-1", "Fire:0", "Thunder:1", "Land:2", "Sea:3") var element: int = -1
## Body tint (placeholder art).
@export var color: Color = Color(0.75, 0.75, 0.75)
## How often the spawner picks this enemy, relative to the others in the pool.
@export var spawn_weight: float = 1.0
## What this enemy can drop when it dies. Null drops nothing.
@export var drop_table: DropTable

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

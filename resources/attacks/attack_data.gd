class_name AttackData
extends Resource
## TEMPORARY (Sprint 1): stats for the stand-in attack. Sprint 2's real spells replace this.

@export var damage: float = 10.0
@export var cooldown: float = 0.35
@export var projectile_speed: float = 220.0
@export var lifetime: float = 1.2
@export var knockback: float = 120.0
@export var projectile_scene: PackedScene

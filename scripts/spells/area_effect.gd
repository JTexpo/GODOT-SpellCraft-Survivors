class_name AreaEffect
extends Node2D
## Base of every Area scene (Line, Cone, Area, Missile, Wave). SpellLoadout instantiates the
## spell's Area scene and calls launch(), and knows nothing else about the Area.


## Call after the effect is in the tree. Subclasses override this.
func launch(_spell: SpellData, _origin: Vector2, _direction: Vector2, _target: Vector2) -> void:
	push_error("AreaEffect.launch must be overridden")


## The one place an Area turns a spell into hit damage. The hitbox carries the raw damage and
## the spell's element, and the target's hurtbox applies the elemental multiplier on impact.
func _configure_hitbox(hitbox: HitboxComponent, spell: SpellData, hit_cooldown: float) -> void:
	hitbox.damage = spell.damage
	hitbox.element = spell.primary_element()
	hitbox.knockback = spell.knockback
	hitbox.hit_cooldown = hit_cooldown

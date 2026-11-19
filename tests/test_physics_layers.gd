extends GutTest

const NAMES: Array[String] = ["world", "player_hurtbox", "enemy_hurtbox", "enemy_hitbox", "player_projectile", "pickup", "interactable"]


func test_layer_names_are_set() -> void:
	for i in NAMES.size():
		var key := "layer_names/2d_physics/layer_%d" % (i + 1)
		assert_eq(ProjectSettings.get_setting(key), NAMES[i], key)


func test_constants_match_layer_bits() -> void:
	assert_eq(PhysicsLayers.WORLD, 1)
	assert_eq(PhysicsLayers.PLAYER_HURTBOX, 2)
	assert_eq(PhysicsLayers.ENEMY_HURTBOX, 4)
	assert_eq(PhysicsLayers.ENEMY_HITBOX, 8)
	assert_eq(PhysicsLayers.PLAYER_PROJECTILE, 16)
	assert_eq(PhysicsLayers.PICKUP, 32)
	assert_eq(PhysicsLayers.INTERACTABLE, 64)

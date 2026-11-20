extends GutTest

const GEM_SCENE := "res://scenes/progression/xp_gem.tscn"


func _gem(amount: int) -> XpGem:
	var gem := (load(GEM_SCENE) as PackedScene).instantiate() as XpGem
	add_child_autofree(gem)
	gem.setup(amount)
	return gem


func test_collect_returns_value_once() -> void:
	var gem := _gem(7)
	assert_eq(gem.collect(), 7)
	assert_eq(gem.collect(), 0)


func test_add_value_stacks() -> void:
	var gem := _gem(3)
	gem.add_value(4)
	assert_eq(gem.value, 7)
	assert_eq(gem.collect(), 7)


func test_gem_scene_is_passive_on_the_pickup_layer() -> void:
	var gem := _gem(1)
	assert_eq(gem.collision_layer, PhysicsLayers.PICKUP)
	assert_eq(gem.collision_mask, 0)
	assert_false(gem.monitoring)
	assert_true(gem.is_in_group(&"xp_gems"))

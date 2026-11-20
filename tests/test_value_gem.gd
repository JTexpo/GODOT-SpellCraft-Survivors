extends GutTest

const GEM_SCENE := "res://scenes/progression/xp_gem.tscn"


func _gem(amount: int) -> ValueGem:
	var gem := (load(GEM_SCENE) as PackedScene).instantiate() as ValueGem
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


func _coin(amount: int) -> ValueGem:
	var coin := (load("res://scenes/progression/gold_coin.tscn") as PackedScene).instantiate() as ValueGem
	add_child_autofree(coin)
	coin.setup(amount)
	return coin


func test_xp_gem_scene_is_the_xp_kind() -> void:
	assert_eq(_gem(1).kind, ValueGem.Kind.XP)


func test_gold_coin_is_passive_on_the_pickup_layer_in_its_own_group() -> void:
	var coin := _coin(2)
	assert_eq(coin.kind, ValueGem.Kind.GOLD)
	assert_eq(coin.collision_layer, PhysicsLayers.PICKUP)
	assert_eq(coin.collision_mask, 0)
	assert_false(coin.monitoring)
	assert_true(coin.is_in_group(&"gold_coins"))
	assert_false(coin.is_in_group(&"xp_gems"))


func test_gold_coin_collects_once_and_stacks_like_a_gem() -> void:
	var coin := _coin(2)
	coin.add_value(3)
	assert_eq(coin.collect(), 5)
	assert_eq(coin.collect(), 0)


func test_coin_and_gem_look_different() -> void:
	var gem := _gem(1)
	var coin := _coin(1)
	assert_ne((gem.get_node("Shape") as Polygon2D).polygon, (coin.get_node("Shape") as Polygon2D).polygon)
	assert_ne((gem.get_node("Shape") as Polygon2D).color, (coin.get_node("Shape") as Polygon2D).color)

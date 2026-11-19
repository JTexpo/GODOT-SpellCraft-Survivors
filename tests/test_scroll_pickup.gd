extends GutTest

const SCENE := "res://scenes/scrolls/scroll_pickup.tscn"
const C := ScrollData.Category


func _scroll(category: ScrollData.Category = C.BASE, color: Color = Color(1, 0.45, 0.1)) -> ScrollData:
	var scroll := ScrollData.new()
	scroll.id = &"test_scroll"
	scroll.category = category
	scroll.color = color
	return scroll


func _pickup(scroll: ScrollData) -> ScrollPickup:
	var pickup := (load(SCENE) as PackedScene).instantiate() as ScrollPickup
	add_child_autofree(pickup)
	pickup.setup(scroll)
	return pickup


func test_pickup_is_passive_on_the_pickup_layer() -> void:
	var pickup := _pickup(_scroll())
	assert_false(pickup.monitoring)
	assert_eq(pickup.collision_layer, PhysicsLayers.PICKUP)
	assert_eq(pickup.collision_mask, 0)


func test_setup_tints_the_shape_with_the_scroll_colour() -> void:
	var scroll := _scroll(C.AREA, Color(0.85, 0.85, 0.9))
	var pickup := _pickup(scroll)
	assert_eq(pickup.scroll, scroll)
	assert_eq((pickup.get_node("Shape") as Polygon2D).color, scroll.color)


func test_shapes_differ_by_category() -> void:
	var base := ScrollPickup.shape_points(C.BASE)
	var area := ScrollPickup.shape_points(C.AREA)
	var buff := ScrollPickup.shape_points(C.BUFF)
	assert_eq(base.size(), 12)
	assert_ne(base, area)
	assert_ne(base, buff)
	assert_ne(area, buff)
	assert_eq((_pickup(_scroll(C.BUFF)).get_node("Shape") as Polygon2D).polygon, buff)


func test_collect_returns_the_scroll_once() -> void:
	var scroll := _scroll()
	var pickup := _pickup(scroll)
	assert_eq(pickup.collect(), scroll)
	assert_null(pickup.collect())
	assert_true(pickup.is_queued_for_deletion())


func test_pickup_joins_the_group() -> void:
	assert_true(_pickup(_scroll()).is_in_group(&"scroll_pickups"))


func test_pickup_does_no_per_frame_work_but_still_bobs() -> void:
	var pickup := _pickup(_scroll())
	assert_false(pickup.is_processing())
	assert_false(pickup.is_physics_processing())
	assert_eq(get_tree().get_processed_tweens().size(), 0, "no tween per pickup")
	assert_true((pickup.get_node("Shape") as Polygon2D).material is ShaderMaterial, "the bob is a shader")

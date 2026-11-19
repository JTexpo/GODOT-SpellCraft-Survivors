extends GutTest


func test_passes_damage_through() -> void:
	assert_eq(DamageSystem.calculate(12.0), 12.0)


func test_negative_damage_clamps_to_zero() -> void:
	assert_eq(DamageSystem.calculate(-5.0), 0.0)

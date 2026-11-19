extends GutTest


func test_ratio_follows_health() -> void:
	var health := HealthComponent.new()
	health.max_health = 100.0
	add_child_autofree(health)
	var bar := load("res://scenes/ui/health_bar.tscn").instantiate() as HealthBar
	add_child_autofree(bar)
	bar.bind(health)
	assert_eq(bar.ratio, 1.0)
	health.take_damage(25.0)
	assert_eq(bar.ratio, 0.75)
	health.take_damage(1000.0)
	assert_eq(bar.ratio, 0.0)

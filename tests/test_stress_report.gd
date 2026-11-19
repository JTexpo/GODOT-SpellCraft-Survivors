extends GutTest


func test_summarize_average_and_fps() -> void:
	var report := StressReport.summarize([16.0, 16.0, 16.0, 16.0] as Array[float])
	assert_eq(report["avg_ms"], 16.0)
	assert_almost_eq(report["avg_fps"] as float, 62.5, 0.01)


func test_summarize_p99_picks_worst_tail() -> void:
	var frames: Array[float] = []
	for i in 99:
		frames.append(10.0)
	frames.append(100.0)
	var report := StressReport.summarize(frames)
	assert_eq(report["p99_ms"], 100.0)


func test_summarize_empty_is_safe() -> void:
	var report := StressReport.summarize([] as Array[float])
	assert_eq(report["avg_ms"], 0.0)
	assert_eq(report["avg_fps"], 0.0)
	assert_eq(report["p99_ms"], 0.0)


func test_stress_scene_spawns_requested_enemies() -> void:
	var scene := load("res://scenes/world/stress_test.tscn").instantiate() as StressTest
	scene.enemy_count = 20
	add_child_autofree(scene)
	await wait_physics_frames(3)
	var count := 0
	for child in scene.get_children():
		if child is Enemy:
			count += 1
	assert_eq(count, 20)

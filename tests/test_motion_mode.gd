extends GutTest

const SCENES: Array[String] = [
	"res://scenes/player/player.tscn",
	"res://scenes/enemies/base_enemy.tscn",
]


func test_top_down_bodies_use_floating_motion_mode() -> void:
	for path in SCENES:
		var body := load(path).instantiate() as CharacterBody2D
		autofree(body)
		assert_eq(body.motion_mode, CharacterBody2D.MOTION_MODE_FLOATING, path)

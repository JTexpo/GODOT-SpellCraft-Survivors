extends GutTest

var _root: Node2D
var _player: Player
var _reticle: TargetReticle


func _ground_spell() -> SpellData:
	var area := AreaData.new()
	area.default_range = 100.0
	area.needs_ground_target = true
	var spell := SpellData.new()
	spell.area_data = area
	return spell


func before_each() -> void:
	_root = Node2D.new()
	add_child_autofree(_root)
	_player = load("res://scenes/player/player.tscn").instantiate() as Player
	_root.add_child(_player)
	_player.global_position = Vector2.ZERO
	_reticle = load("res://scenes/ui/target_reticle.tscn").instantiate() as TargetReticle
	_root.add_child(_reticle)
	_reticle.bind(_player)


func _use_ground_spell() -> void:
	_player.loadout.slots[0] = SpellInstance.new(_ground_spell())


func test_reticle_hidden_for_a_missile_spell() -> void:
	_reticle._process(0.0)
	assert_false(_reticle.visible)


func test_reticle_shows_at_the_clamped_target_for_a_ground_spell() -> void:
	_use_ground_spell()
	_player.aim.aim_point = Vector2(300, 0)
	_reticle._process(0.0)
	assert_true(_reticle.visible)
	assert_eq(_reticle.global_position, Vector2(100, 0))
	_player.aim.aim_point = Vector2(40, 0)
	_reticle._process(0.0)
	assert_eq(_reticle.global_position, Vector2(40, 0))


func test_reticle_hides_when_the_player_dies() -> void:
	_use_ground_spell()
	_player.aim.aim_point = Vector2(40, 0)
	_reticle._process(0.0)
	assert_true(_reticle.visible)
	(_player.get_node("HurtboxComponent") as HurtboxComponent).receive_hit(1000.0, Vector2.ZERO)
	_reticle._process(0.0)
	assert_false(_reticle.visible)

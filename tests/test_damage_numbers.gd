extends GutTest

const N := ElementTable.Effect

var _numbers: DamageNumbers


func before_each() -> void:
	_numbers = DamageNumbers.new()
	add_child_autofree(_numbers)


func test_starts_idle() -> void:
	assert_eq(_numbers.active_count(), 0)
	assert_false(_numbers.is_processing())


func test_show_number_activates_it() -> void:
	_numbers.show_number(Vector2(10, 10), 5.0, N.NEUTRAL)
	assert_eq(_numbers.active_count(), 1)
	assert_true(_numbers.is_processing())


func test_text_rounds_and_is_at_least_one() -> void:
	_numbers.show_number(Vector2.ZERO, 14.6, N.NEUTRAL)
	_numbers.show_number(Vector2.ZERO, 0.4, N.RESISTED)
	_numbers.show_number(Vector2.ZERO, 15.0, N.VULNERABLE)
	assert_eq(_numbers.active_texts(), ["15", "1", "15!"])


func test_numbers_expire_and_processing_stops() -> void:
	_numbers.show_number(Vector2.ZERO, 5.0, N.NEUTRAL)
	_numbers._process(DamageNumbers.LIFETIME + 0.01)
	assert_eq(_numbers.active_count(), 0)
	assert_false(_numbers.is_processing())


func test_never_exceeds_the_pool() -> void:
	for i in 200:
		_numbers.show_number(Vector2.ZERO, float(i + 1), N.NEUTRAL)
	assert_eq(_numbers.active_count(), DamageNumbers.POOL_SIZE)


func test_full_pool_replaces_the_oldest() -> void:
	for i in DamageNumbers.POOL_SIZE:
		_numbers.show_number(Vector2.ZERO, float(i + 1), N.NEUTRAL)
	_numbers.show_number(Vector2.ZERO, 65.0, N.NEUTRAL)
	var texts := _numbers.active_texts()
	assert_false(texts.has("1"))
	assert_true(texts.has("2"))
	assert_eq(texts.back(), "65")
	assert_eq(texts.size(), DamageNumbers.POOL_SIZE)


func test_style_by_effect() -> void:
	var neutral := DamageNumbers.style_for(N.NEUTRAL)
	assert_eq(neutral["color"], Color.WHITE)
	assert_eq(neutral["size"], 8)
	assert_eq(neutral["suffix"], "")
	var vulnerable := DamageNumbers.style_for(N.VULNERABLE)
	assert_eq(vulnerable["color"], Color(1, 0.9, 0.2))
	assert_eq(vulnerable["size"], 12)
	assert_eq(vulnerable["suffix"], "!")
	var resisted := DamageNumbers.style_for(N.RESISTED)
	assert_eq(resisted["color"], Color(0.6, 0.6, 0.6))
	assert_eq(resisted["size"], 6)
	assert_eq(resisted["suffix"], "")
	assert_eq(DamageNumbers.style_for(99), neutral)


func test_numbers_age_independently() -> void:
	_numbers.show_number(Vector2.ZERO, 1.0, N.NEUTRAL)
	_numbers._process(0.4)
	_numbers.show_number(Vector2.ZERO, 2.0, N.NEUTRAL)
	_numbers._process(0.3)
	assert_eq(_numbers.active_texts(), ["2"])

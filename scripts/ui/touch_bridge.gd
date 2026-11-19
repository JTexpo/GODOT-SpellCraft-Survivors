class_name TouchBridge
extends RefCounted
## The project turns mouse emulation from touch off (so touching a stick never fires a spell), so
## ordinary buttons would ignore a finger. A modal screen uses this to turn a touch into the left
## mouse press or release the buttons expect.


static func to_mouse_button(event: InputEventScreenTouch) -> InputEventMouseButton:
	var mouse := InputEventMouseButton.new()
	mouse.button_index = MOUSE_BUTTON_LEFT
	mouse.pressed = event.pressed
	mouse.position = event.position
	mouse.global_position = event.position
	mouse.button_mask = MOUSE_BUTTON_MASK_LEFT if event.pressed else 0
	return mouse

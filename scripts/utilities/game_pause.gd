class_name GamePause
extends RefCounted
## Pauses or resumes the whole world together with the pause-aware clock, so a timer that
## ought to stop during a pause really does. Nodes opt out with process_mode = Always.


static func set_paused(tree: SceneTree, paused: bool) -> void:
	tree.paused = paused
	if paused:
		GameTime.freeze()
	else:
		GameTime.unfreeze()

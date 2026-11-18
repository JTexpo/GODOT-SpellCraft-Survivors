class_name SceneSwitcher
extends RefCounted


static func change_to(tree: SceneTree, path: String) -> Error:
	if path.is_empty() or not ResourceLoader.exists(path):
		return ERR_FILE_NOT_FOUND
	return tree.change_scene_to_file(path)

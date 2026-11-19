class_name StressReport
extends RefCounted


static func summarize(frame_ms: Array[float]) -> Dictionary:
	if frame_ms.is_empty():
		return {"avg_ms": 0.0, "avg_fps": 0.0, "p99_ms": 0.0}
	var total := 0.0
	for value in frame_ms:
		total += value
	var avg := total / frame_ms.size()
	var sorted := frame_ms.duplicate()
	sorted.sort()
	var index := mini(ceili(sorted.size() * 0.99), sorted.size() - 1)
	return {
		"avg_ms": avg,
		"avg_fps": 1000.0 / avg if avg > 0.0 else 0.0,
		"p99_ms": sorted[index],
	}

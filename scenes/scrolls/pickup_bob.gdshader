shader_type canvas_item;
// Makes a scroll pickup bob up and down on the GPU, so no pickup runs a tween or any script each
// frame. The phase comes from the pickup's position, so a pile of scrolls does not bob in step.

uniform float height = 1.5;
uniform float speed = 4.0;

void vertex() {
	float phase = MODEL_MATRIX[3].x * 0.13 + MODEL_MATRIX[3].y * 0.07;
	VERTEX.y += sin(TIME * speed + phase) * height;
}

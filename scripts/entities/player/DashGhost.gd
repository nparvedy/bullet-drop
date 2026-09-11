extends Node2D

var alpha: float = 0.6

func _process(delta: float) -> void:
	alpha -= delta * 3.5
	if alpha <= 0.0:
		queue_free()
	else:
		queue_redraw()

func _draw() -> void:
	draw_circle(Vector2.ZERO, 16.0, Color(0.3, 0.7, 1.0, alpha * 0.5))
	draw_arc(Vector2.ZERO, 16.0, 0, TAU, 32, Color(0.1, 0.4, 0.9, alpha), 2.0, true)

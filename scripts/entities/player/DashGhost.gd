extends Sprite2D

var alpha: float = 0.6

func _process(delta: float) -> void:
	alpha -= delta * 3.5
	modulate.a = max(0.0, alpha)
	if alpha <= 0.0:
		queue_free()

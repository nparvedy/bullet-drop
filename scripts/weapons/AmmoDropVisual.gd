extends Node2D

func _draw() -> void:
	# Boîte de munitions
	var box_rect = Rect2(-8, -6, 16, 12)
	draw_rect(box_rect, Color(0.2, 0.35, 0.2), true) # Vert militaire
	draw_rect(box_rect, Color(0.1, 0.2, 0.1), false, 1.5) # Bordure
	
	# Balles dorées / chargeur stylisé
	draw_rect(Rect2(-5, -4, 3, 8), Color(1.0, 0.8, 0.1), true)
	draw_rect(Rect2(-1, -4, 3, 8), Color(1.0, 0.8, 0.1), true)
	draw_rect(Rect2(3, -4, 3, 8), Color(1.0, 0.8, 0.1), true)
	
	# Reflet
	draw_line(Vector2(-7, -5), Vector2(7, -5), Color(0.4, 0.6, 0.4), 1.0)

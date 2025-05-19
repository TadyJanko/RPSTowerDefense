extends Node2D

var radius := 150
var color := Color(0, 0, 1, 0.15)

func _draw():
	draw_circle(Vector2.ZERO, radius, color)

func set_radius(r):
	radius = r
	queue_redraw() 

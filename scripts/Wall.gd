extends Node2D

signal tower_selected(tower)
signal tower_deselected(tower)

var base_cost = 20

func _ready():
	var sprite = find_child("Sprite2D", true, false)
	if sprite:
		sprite.texture = load("res://assets/wall.png")

func get_sell_value():
	return base_cost * 0.5

func is_point_inside(point: Vector2) -> bool:
	var sprite = find_child("Sprite2D", true, false)
	if sprite and sprite.texture:
		var size = sprite.texture.get_size() * sprite.scale
		var rect = Rect2(global_position - size * 0.5, size)
		return rect.has_point(point)
	return false

func select():
	tower_selected.emit(self)

func deselect():
	tower_deselected.emit(self) 
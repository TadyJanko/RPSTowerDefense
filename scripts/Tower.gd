extends Node2D

signal tower_selected(tower)
signal tower_deselected(tower)

var damage = 20
var range_radius = 150
var projectile_scene = preload("res://scenes/Projectile.tscn")
var tower_type = "rock"
var is_selected = false

func _ready():
	$Timer.timeout.connect(_on_timer_timeout)
	$RangeIndicator.set_radius(range_radius)
	set_visual_by_type()

func _unhandled_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if is_point_inside(get_global_mouse_position()):
			if not is_selected:
				select()
			else:
				deselect()

func select():
	is_selected = true
	show_range(true)
	tower_selected.emit(self)

func deselect():
	is_selected = false
	show_range(false)
	tower_deselected.emit(self)

func set_tower_type(t_type):
	tower_type = t_type
	set_visual_by_type()

func set_visual_by_type():
	var sprite = find_child("Sprite2D", true, false)
	if sprite:
		match tower_type:
			"rock":
				sprite.texture = load("res://assets/rock-tower.png")
			"paper":
				sprite.texture = load("res://assets/paper-cannon.png")
			"scissors":
				sprite.texture = load("res://assets/scissors-cannon.png")
	else:
		print("ERROR: Sprite2D not found in Tower node tree!")

func _on_timer_timeout():
	var enemies = get_tree().get_nodes_in_group("enemies")
	var closest_enemy = null
	var closest_distance = range_radius
	
	for enemy in enemies:
		var distance = global_position.distance_to(enemy.global_position)
		if distance < closest_distance:
			closest_enemy = enemy
			closest_distance = distance
	
	if closest_enemy:
		var projectile = projectile_scene.instantiate()
		projectile.target = closest_enemy
		projectile.range_radius = range_radius  # Set the projectile's range to match tower's range
		projectile.tower_type = tower_type
		projectile.set_visual_by_type() # Set projectile color
		add_child(projectile) 

func show_range(visible: bool):
	if has_node("RangeIndicator"):
		$RangeIndicator.visible = visible

func is_point_inside(point: Vector2) -> bool:
	var sprite = find_child("Sprite2D", true, false)
	if sprite and sprite.texture:
		var size = sprite.texture.get_size() * sprite.scale
		var rect = Rect2(global_position - size * 0.5, size)
		return rect.has_point(point)
	return false

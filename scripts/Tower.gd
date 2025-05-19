extends Node2D

signal tower_selected(tower)
signal tower_deselected(tower)

var base_damage = 20
var damage = 20
var range_radius = 150
var projectile_scene = preload("res://scenes/Projectile.tscn")
var tower_type = "rock"
var is_selected = false
var level = 1
var base_cost = 100
var upgrade_cost = 200  # Cost for next upgrade
var total_cost = 100    # Total cost including upgrades
var slow_amount = 0.0625
var is_money_tower = false
var money_timer = 0.0
var money_delay = 1.0
var slowed_enemies = {} # enemy: original_speed

func _ready():
	add_to_group("towers")
	$Timer.timeout.connect(_on_timer_timeout)
	$RangeIndicator.set_radius(range_radius)
	set_visual_by_type()
	update_level_label()
	update_shoot_speed()

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
	if tower_type == "money":
		is_money_tower = true
	else:
		is_money_tower = false

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
			"money":
				sprite.texture = load("res://assets/Money.png")
			"slow":
				sprite.texture = load("res://assets/Slow.png")
	else:
		print("ERROR: Sprite2D not found in Tower node tree!")

func _on_timer_timeout():
	if tower_type == "slow":
		var enemies = get_tree().get_nodes_in_group("enemies")
		var closest_enemy = null
		var closest_distance = range_radius
		for enemy in enemies:
			var distance = global_position.distance_to(enemy.global_position)
			if distance < closest_distance:
				closest_enemy = enemy
				closest_distance = distance
		if closest_enemy:
			# Apply slow effect (stacking)
			if not closest_enemy.has_meta("slow_stack"):
				closest_enemy.set_meta("slow_stack", 1)
			else:
				closest_enemy.set_meta("slow_stack", closest_enemy.get_meta("slow_stack") + 1)
			closest_enemy.speed *= (1.0 - slow_amount)
	elif not is_money_tower:
		# Normal attack logic for other towers
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
			projectile.range_radius = range_radius
			projectile.tower_type = tower_type
			projectile.damage = damage
			projectile.set_visual_by_type()
			add_child(projectile)

func show_range(visible: bool):
	if tower_type == "money":
		$RangeIndicator.visible = false
		return
	if has_node("RangeIndicator"):
		$RangeIndicator.visible = visible

func is_point_inside(point: Vector2) -> bool:
	var sprite = find_child("Sprite2D", true, false)
	if sprite and sprite.texture:
		var size = sprite.texture.get_size() * sprite.scale
		var rect = Rect2(global_position - size * 0.5, size)
		return rect.has_point(point)
	return false

func upgrade():
	if level < 3:  # Maximum level is 3
		level += 1
		damage = base_damage * pow(3, level - 1)  # Triple damage each level
		upgrade_cost *= 2  # Double cost for next upgrade
		total_cost += upgrade_cost
		range_radius += 100  # Increase range by 100 each level
		$RangeIndicator.set_radius(range_radius)  # Update the visual range indicator
		update_level_label()
		update_shoot_speed()
		return true
	return false

func update_shoot_speed():
	if has_node("Timer"):
		var base_time = 0.5
		$Timer.wait_time = base_time * pow(0.8, level - 1)

func get_sell_value():
	return total_cost * 0.5  # 50% refund

func update_level_label():
	if not has_node("LevelLabel"):
		var label = Label.new()
		label.name = "LevelLabel"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		add_child(label)
	
	$LevelLabel.text = "Lvl " + str(level)
	$LevelLabel.position = Vector2(-20, 40)  # Position below the tower

func _process(delta):
	if is_money_tower:
		if get_tree().get_root().get_node("Main").game_over:
			return
		money_timer -= delta
		var money_per_tick = int(pow(2, level)) # 2, 4, 8 for levels 1,2,3
		if money_timer <= 0:
			money_timer = money_delay
			get_tree().get_root().get_node("Main").add_money(money_per_tick)
			var text = preload("res://scenes/FloatingText.tscn").instantiate()
			get_parent().add_child(text)
			text.global_position = global_position
			var label = text.get_node("Label")
			label.text = "+" + str(money_per_tick)
	elif tower_type == "slow":
		var slow_percent = 0.125 * level
		var enemies = get_tree().get_nodes_in_group("enemies")
		for enemy in enemies:
			if global_position.distance_to(enemy.global_position) < range_radius:
				enemy.speed = enemy.base_speed * (1.0 - slow_percent)
			else:
				enemy.speed = enemy.base_speed

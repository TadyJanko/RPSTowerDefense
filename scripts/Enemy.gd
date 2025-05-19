extends CharacterBody2D

var speed = 67  # Reduced from 200 to make it 3x slower
var base_speed = 67
var health = 100
var max_health = 100
var floating_text_scene = preload("res://scenes/FloatingText.tscn")
var enemy_type = "rock" # default, set when spawning
var enemy_level = 1

func _ready():
	add_to_group("enemies")
	base_speed = speed
	$HealthBar.max_value = max_health
	$HealthBar.value = health
	set_visual_by_type()
	if not has_node("LevelLabel"):
		var label = Label.new()
		label.name = "LevelLabel"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		add_child(label)
	$LevelLabel.text = "Lvl " + str(enemy_level)
	$LevelLabel.position = Vector2(-10, 35)
	set_level(enemy_level)

func set_visual_by_type():
	var sprite = find_child("Sprite2D", true, false)
	if sprite:
		sprite.scale = Vector2(0.5, 0.5)
		match enemy_type:
			"rock":
				sprite.texture = load("res://assets/rock-enemy.png")
			"paper":
				sprite.texture = load("res://assets/paper-enemy.png")
			"scissors":
				sprite.texture = load("res://assets/scissors-enemy.png")
	else:
		print("ERROR: Sprite2D not found in Enemy node tree!")

func _physics_process(delta):
	var base_velocity = Vector2(speed, 0)
	var attempted = [Vector2(0, 0), Vector2(0, -30), Vector2(0, 30)] # right, up, down
	var moved = false
	for offset in attempted:
		var velocity = base_velocity + offset
		var collision = move_and_collide(velocity * delta)
		# No need to check for collision with towers here
		if not collision:
			moved = true
			break

	# Manual overlap check with towers
	for tower in get_tree().get_nodes_in_group("towers"):
		if global_position.distance_to(tower.global_position) < 32: # 32 pixels threshold, adjust as needed
			# Subtract 50 points from score
			get_tree().get_root().get_node("Main").add_score(-50)
			# Show red floating text
			var text = floating_text_scene.instantiate()
			get_parent().add_child(text)
			text.global_position = global_position
			var label = text.get_node("Label")
			label.text = "-50"
			label.modulate = Color(1, 0, 0, 1) # Red
			tower.queue_free()
			queue_free()
			return

	# If all directions are blocked, enemy waits (does not move)
	if position.x > 1536: # right edge for new resolution
		get_parent().get_parent().lose_life()
		queue_free()

# Now takes two arguments: amount, tower_type
func take_damage(amount, tower_type):
	var multiplier = 1.0
	if tower_type == enemy_type:
		multiplier = 1.0
	elif (tower_type == "rock" and enemy_type == "scissors") or (tower_type == "scissors" and enemy_type == "paper") or (tower_type == "paper" and enemy_type == "rock"):
		multiplier = 2.0
	elif (tower_type == "scissors" and enemy_type == "rock") or (tower_type == "paper" and enemy_type == "scissors") or (tower_type == "rock" and enemy_type == "paper"):
		multiplier = 0.5
	health -= amount * multiplier
	$HealthBar.value = health
	if health <= 0:
		# Spawn floating text
		var text = floating_text_scene.instantiate()
		get_parent().add_child(text)
		text.global_position = global_position
		var label = text.get_node("Label")
		label.text = "+10"
		get_tree().get_root().get_node("Main").add_money(10)
		get_tree().get_root().get_node("Main").add_score(10)
		queue_free() 

func set_level(lvl):
	enemy_level = lvl
	max_health = 100 * pow(2, enemy_level-1)
	health = max_health
	speed = 67 * pow(1.2, enemy_level-1)
	$HealthBar.max_value = max_health
	$HealthBar.value = health
	if has_node("LevelLabel"):
		$LevelLabel.text = "Lvl " + str(enemy_level)

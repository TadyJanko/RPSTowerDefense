extends CharacterBody2D

var speed = 67  # Reduced from 200 to make it 3x slower
var health = 100
var max_health = 100
var floating_text_scene = preload("res://scenes/FloatingText.tscn")
var enemy_type = "rock" # default, set when spawning

func _ready():
	add_to_group("enemies")
	$HealthBar.max_value = max_health
	$HealthBar.value = health
	set_visual_by_type()

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
	velocity.x = speed
	move_and_slide()
	
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
		get_parent().get_parent().add_money(20)
		queue_free() 
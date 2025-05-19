extends Node2D

var lives = 10
var money = 300  # Start with 300 coins
var enemy_scene = preload("res://scenes/Enemy.tscn")
var selected_tower_type = null  # For tower placement
var selected_tower = null  # For tower selection
var tower_scenes = {
	"rock": preload("res://scenes/Tower_Rock.tscn"),
	"paper": preload("res://scenes/Tower_Paper.tscn"),
	"scissors": preload("res://scenes/Tower_Scissors.tscn")
}
var spawn_timer = 0
var spawn_delay = 2.0  # seconds between spawns
var money_timer = 0
var money_delay = 1.0  # seconds between money increments

func _ready():
	update_ui()
	$UI/TowerButtons/RockButton.pressed.connect(_on_rock_button_pressed)
	$UI/TowerButtons/PaperButton.pressed.connect(_on_paper_button_pressed)
	$UI/TowerButtons/ScissorsButton.pressed.connect(_on_scissors_button_pressed)
	
	# Connect tower selection signals
	for tower in get_tree().get_nodes_in_group("towers"):
		tower.tower_selected.connect(_on_tower_selected)
		tower.tower_deselected.connect(_on_tower_deselected)

func _process(delta):
	spawn_timer -= delta
	if spawn_timer <= 0:
		spawn_enemy()
		spawn_timer = spawn_delay
	
	money_timer -= delta
	if money_timer <= 0:
		money += 10
		update_ui()
		money_timer = money_delay

	# Update tower ranges
	for tower in get_tree().get_nodes_in_group("towers"):
		if tower == selected_tower:
			tower.show_range(true)
		else:
			tower.show_range(false)

func _unhandled_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if selected_tower_type:
			# Place tower at mouse position
			var tower_instance = tower_scenes[selected_tower_type].instantiate()
			tower_instance.position = get_global_mouse_position()
			tower_instance.set_tower_type(selected_tower_type)  # Set the tower type
			add_child(tower_instance)
			tower_instance.tower_selected.connect(_on_tower_selected)
			tower_instance.tower_deselected.connect(_on_tower_deselected)
			selected_tower_type = null

func _on_rock_button_pressed():
	selected_tower_type = "rock"

func _on_paper_button_pressed():
	selected_tower_type = "paper"

func _on_scissors_button_pressed():
	selected_tower_type = "scissors"

func _on_tower_selected(tower):
	selected_tower_type = null
	selected_tower = tower
	for t in get_tree().get_nodes_in_group("towers"):
		if t != tower:
			t.deselect()

func _on_tower_deselected(_tower):
	selected_tower_type = null
	selected_tower = null

func update_ui():
	$UI/LivesLabel.text = "Lives: " + str(lives)
	$UI/MoneyLabel.text = "Money: " + str(money)

func lose_life():
	lives -= 1
	update_ui()
	if lives <= 0:
		get_tree().quit()

func add_money(amount):
	money += amount
	update_ui()

func spawn_enemy():
	var enemy = enemy_scene.instantiate()
	var types = ["rock", "paper", "scissors"]
	enemy.enemy_type = types[randi() % 3]
	enemy.set_visual_by_type()
	enemy.position = Vector2(-30, randf_range(450, 600))
	$EnemySpawner.add_child(enemy)

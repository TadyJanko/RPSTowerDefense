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
	$UI/ExitButton.pressed.connect(_on_exit_button_pressed)
	
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
		else:
			# Check if we clicked on a tower
			var clicked_tower = null
			for tower in get_tree().get_nodes_in_group("towers"):
				if tower.is_point_inside(get_global_mouse_position()):
					clicked_tower = tower
					break
			
			# If we clicked on a tower, select it
			if clicked_tower:
				if selected_tower != clicked_tower:
					if selected_tower:
						selected_tower.deselect()
					clicked_tower.select()
			# If we clicked elsewhere, deselect current tower
			elif selected_tower:
				selected_tower.deselect()

func _on_rock_button_pressed():
	selected_tower_type = "rock"

func _on_paper_button_pressed():
	selected_tower_type = "paper"

func _on_scissors_button_pressed():
	selected_tower_type = "scissors"

func _on_tower_selected(tower):
	selected_tower_type = null
	selected_tower = tower
	show_tower_buttons(tower)

func _on_tower_deselected(_tower):
	selected_tower_type = null
	selected_tower = null
	hide_tower_buttons()

func _on_upgrade_button_pressed():
	if selected_tower and money >= selected_tower.upgrade_cost:
		if selected_tower.upgrade():
			money -= selected_tower.upgrade_cost
			update_ui()
			update_tower_buttons()

func show_tower_buttons(tower):
	if not has_node("UI/TowerButtons/UpgradeButton"):
		var upgrade_button = Button.new()
		upgrade_button.name = "UpgradeButton"
		upgrade_button.text = "Upgrade"
		upgrade_button.pressed.connect(_on_upgrade_button_pressed)
		$UI/TowerButtons.add_child(upgrade_button)
	
	update_tower_buttons()

func hide_tower_buttons():
	if has_node("UI/TowerButtons/UpgradeButton"):
		$UI/TowerButtons/UpgradeButton.visible = false

func update_tower_buttons():
	if selected_tower:
		var upgrade_button = $UI/TowerButtons/UpgradeButton
		upgrade_button.visible = true
		
		if selected_tower.level < 3:
			upgrade_button.text = "Upgrade (" + str(selected_tower.upgrade_cost) + ")"
			upgrade_button.disabled = money < selected_tower.upgrade_cost
		else:
			upgrade_button.text = "Max Level"
			upgrade_button.disabled = true

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
	enemy.position = Vector2(-30, randf_range(475, 540))  # Optimal spawn range
	$EnemySpawner.add_child(enemy)

func _on_exit_button_pressed():
	get_tree().quit()

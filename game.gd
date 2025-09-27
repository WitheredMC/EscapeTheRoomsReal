extends Node2D

# --- Config ---
var player_speed = 200
var enemy_speed = 100
var level_data = [
	{"name":"Level 1: The Dark Cellar","sacrifices":2, "positions":[Vector2(0.25,0.33), Vector2(0.75,0.66)], "enemies":[Vector2(0.5,0.16)]},
	{"name":"Level 2: The Forsaken Hall","sacrifices":3, "positions":[Vector2(0.125,0.166), Vector2(0.5,0.5), Vector2(0.875,0.333)], "enemies":[Vector2(0.25,0.833), Vector2(0.75,0.166)]},
	{"name":"Level 3: The Blood Chamber","sacrifices":4, "positions":[Vector2(0.125,0.166), Vector2(0.375,0.333), Vector2(0.625,0.666), Vector2(0.875,0.5)], "enemies":[Vector2(0.5,0.25), Vector2(0.75,0.666), Vector2(0.25,0.5)]}
]

# --- Nodes ---
var player
var sacrifices = []
var enemies = []
var enemy_targets = []
var exit_area
var sacrifices_done = 0
var space_pressed_last_frame = false

var level_index = 0

var message_label
var controls_label
var showing_message = true
var message_timer = 0

var screen_size = Vector2.ZERO

func _ready():
	# Maximize window
	DisplayServer.window_set_mode(DisplayServer.WindowMode.WINDOW_MODE_MAXIMIZED)
	# Convert Vector2i to Vector2
	var win_size = DisplayServer.window_get_size()
	screen_size = Vector2(win_size.x, win_size.y)

	_setup_scene()
	_load_level(level_index)
	_show_message("You Must Sacrifice Something...")

func _process(delta):
	if showing_message:
		message_timer -= delta
		if message_timer <= 0:
			message_label.text = ""
			showing_message = false
	else:
		_move_player(delta)
		_move_enemies(delta)
		_check_sacrifice()
		_check_exit()
		_check_collision_with_enemies()
		_keep_player_inside_room()

# --- Scene Setup ---
func _setup_scene():
	# Floor
	var floor = ColorRect.new()
	floor.color = Color(0.1,0.1,0.1)
	floor.size = screen_size
	add_child(floor)
	# Walls
	_create_walls()
	# Player
	player = ColorRect.new()
	player.color = Color.WHITE
	player.size = screen_size * Vector2(0.04,0.053)
	player.position = screen_size / 2
	add_child(player)
	# Exit
	exit_area = ColorRect.new()
	exit_area.color = Color.GREEN
	exit_area.size = player.size
	exit_area.visible = false
	add_child(exit_area)
	# Messages
	message_label = Label.new()
	message_label.position = Vector2(screen_size.x*0.1, 10)
	message_label.modulate = Color(1,0,0)
	add_child(message_label)
	controls_label = Label.new()
	controls_label.text = "Move: W/A/S/D    Sacrifice: SPACE"
	controls_label.position = Vector2(screen_size.x*0.1, screen_size.y*0.95)
	controls_label.modulate = Color(1,1,1)
	add_child(controls_label)

# --- Player Movement ---
func _move_player(delta):
	var vel = Vector2.ZERO
	if Input.is_key_pressed(KEY_W):
		vel.y -= 1
	if Input.is_key_pressed(KEY_S):
		vel.y += 1
	if Input.is_key_pressed(KEY_A):
		vel.x -= 1
	if Input.is_key_pressed(KEY_D):
		vel.x += 1
	vel = vel.normalized() * player_speed
	player.position += vel * delta

# --- Enemy Movement (Patrol) ---
func _move_enemies(delta):
	for i in range(enemies.size()):
		var enemy = enemies[i]
		if enemy:
			var target = enemy_targets[i]
			var dir = (target - enemy.position)
			if dir.length() < 5:
				target = Vector2(randf() * (screen_size.x*0.92) + screen_size.x*0.04,
								 randf() * (screen_size.y*0.894) + screen_size.y*0.053)
				enemy_targets[i] = target
				dir = target - enemy.position
			enemy.position += dir.normalized() * enemy_speed * delta

# --- Sacrifice ---
func _check_sacrifice():
	var space_pressed = Input.is_key_pressed(KEY_SPACE)
	if space_pressed and not space_pressed_last_frame:
		for i in range(sacrifices.size()):
			var sac = sacrifices[i]
			if sac and player.get_global_rect().intersects(Rect2(sac.position, sac.size)):
				sac.color = Color.BLACK
				sac.queue_free()
				sacrifices[i] = null
				sacrifices_done += 1
				if sacrifices_done >= level_data[level_index]["sacrifices"]:
					exit_area.visible = true
	space_pressed_last_frame = space_pressed

# --- Exit ---
func _check_exit():
	if exit_area.visible and player.get_global_rect().intersects(Rect2(exit_area.position, exit_area.size)):
		if level_index < level_data.size() - 1:
			level_index += 1
			_show_message("Next Level: " + level_data[level_index]["name"])
			_load_level(level_index)
		else:
			_show_message("You Escaped!")

# --- Collision with enemies ---
func _check_collision_with_enemies():
	for enemy in enemies:
		if enemy and player.get_global_rect().intersects(Rect2(enemy.position, enemy.size)):
			_show_message("You were caught! Restarting...")
			level_index = 0
			_load_level(level_index)
			break

# --- Load level ---
func _load_level(index):
	# Clear sacrifices
	for sac in sacrifices:
		if sac:
			sac.queue_free()
	sacrifices.clear()
	# Add new sacrifices
	for pos_frac in level_data[index]["positions"]:
		var sac = ColorRect.new()
		sac.color = Color.RED
		sac.size = player.size * 0.75
		sac.position = Vector2(pos_frac.x * screen_size.x, pos_frac.y * screen_size.y)
		add_child(sac)
		sacrifices.append(sac)
	# Clear enemies
	for e in enemies:
		if e:
			e.queue_free()
	enemies.clear()
	enemy_targets.clear()
	for pos_frac in level_data[index]["enemies"]:
		var e = ColorRect.new()
		e.color = Color(1,0.5,0)
		e.size = player.size * 0.875
		e.position = Vector2(pos_frac.x * screen_size.x, pos_frac.y * screen_size.y)
		add_child(e)
		enemies.append(e)
		var target = Vector2(randf() * (screen_size.x*0.92) + screen_size.x*0.04,
							 randf() * (screen_size.y*0.894) + screen_size.y*0.053)
		enemy_targets.append(target)
	# Exit
	exit_area.position = Vector2(0.9375*screen_size.x, 0.9166*screen_size.y)
	exit_area.size = player.size
	exit_area.visible = false
	# Reset player
	player.position = screen_size / 2
	sacrifices_done = 0

# --- Messages ---
func _show_message(text):
	message_label.text = text
	message_timer = 2.0
	showing_message = true

# --- Keep player inside walls ---
func _keep_player_inside_room():
	var min_x = screen_size.x*0.04
	var max_x = screen_size.x - player.size.x - screen_size.x*0.04
	var min_y = screen_size.y*0.053
	var max_y = screen_size.y - player.size.y - screen_size.y*0.053
	player.position.x = clamp(player.position.x, min_x, max_x)
	player.position.y = clamp(player.position.y, min_y, max_y)

# --- Walls ---
func _create_walls():
	var thickness_x = screen_size.x * 0.04
	var thickness_y = screen_size.y * 0.053
	var walls = [
		Rect2(0,0,screen_size.x,thickness_y),
		Rect2(0,screen_size.y-thickness_y,screen_size.x,thickness_y),
		Rect2(0,0,thickness_x,screen_size.y),
		Rect2(screen_size.x-thickness_x,0,thickness_x,screen_size.y)
	]
	for w in walls:
		var wall = ColorRect.new()
		wall.color = Color(0.2,0.2,0.2)
		wall.position = w.position
		wall.size = w.size
		add_child(wall)

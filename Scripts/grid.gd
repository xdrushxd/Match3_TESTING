extends Node2D

# State Machine for the move pieces to move once
enum { wait, move }
var state

# Grid variables
@export var width: int
@export var height: int
@export var x_start: int
@export var y_start: int
@export var offset: int
@export var y_offset: int

# Obstacle stuff
@export var empty_spaces = PackedVector2Array()
@export var ice_spaces = PackedVector2Array()
@export var lock_spaces = PackedVector2Array()
@export var concrete_spaces = PackedVector2Array()
@export var slime_spaces = PackedVector2Array()
var damaged_slime = false

# Obstical signals
signal make_ice
signal damage_ice
signal make_lock
signal damage_lock
signal make_concrete
signal damage_concrete
signal make_slime
signal damage_slime

# The Piece Array
var possible_pieces = [
	preload("res://scenes/yellow_piece.tscn"),
	preload("res://scenes/blue_piece.tscn"),
	preload("res://scenes/pink_piece.tscn"),
	preload("res://scenes/green_piece.tscn"),
	preload("res://scenes/light_green_piece.tscn"),
	preload("res://scenes/orange_piece.tscn")
]

# The current pieces in the scene
var all_pieces: Array
var current_matches = []

#swap back variables
var piece_one = null
var piece_two = null
var last_place = Vector2(0,0)
var last_direction = Vector2(0,0)
var move_checked = false

# The Touch Variables
var first_touch = Vector2(0, 0);
var final_touch = Vector2(0, 0);
var controlling = false

func _ready() -> void:
	state = move
	all_pieces = makeGrid()
	spawnPieces()
	spawn_ice()
	spawn_locks()
	spawn_concrete()
	spawn_slime()




func restricted_fill(place):
	#Check the empty pieces
	if is_in_array(empty_spaces, place):
		return true
	if is_in_array(concrete_spaces, place):
		return true
	if is_in_array(slime_spaces, place):
		return true
	return false

func restricted_move(place):
	#Check Licorice/lock pieces
	if is_in_array(lock_spaces, place):
		return true
	return false


func is_in_array(array, item):
	for i in array.size():
		if array[i] == item:
			return true
	return false

func remove_from_array(array, item):
	for i in range(array.size() - 1, -1, -1):
		if array[i] == item:
			array.remove_at(i)


# Obv makes grid
func makeGrid() -> Array:
	var grid: Array = []
	for i in range(width):
		var row: Array = []
		for j in range(height):
			row.append(null)
		grid.append(row)
	return grid


# Spawns my blocks/pieces
func spawnPieces() -> void:
	for i in range(width):
		for j in range(height):
			if !restricted_fill(Vector2(i,j)):
				var piece_instance = getValidPieceInstance(i, j)
				if piece_instance:
					add_child(piece_instance)
					piece_instance.position = gridToPixel(i, j)
					all_pieces[i][j] = piece_instance

func getValidPieceInstance(i: int, j: int) -> Node2D:
	var loops = 0
	while loops < 100:
		var rand = randi() % possible_pieces.size()
		var piece_scene = possible_pieces[rand]
		var piece_instance = piece_scene.instantiate() as Node2D
		if not matchAt(i, j, piece_instance.color):
			return piece_instance
		loops += 1
	return null

func matchAt(_x: int, _y: int, color: String) -> bool:
	# Check if there is a matching piece at the given position
	# You need to implement this function based on your game's logic
	# and return true if there is a match, false otherwise.
	return false



func spawn_ice():
	for i in range(ice_spaces.size()):
		emit_signal("make_ice", ice_spaces[i])

func spawn_locks():
	for i in lock_spaces.size():
		emit_signal("make_lock", lock_spaces[i])


func spawn_concrete():
	for i in concrete_spaces.size():
		emit_signal("make_concrete", concrete_spaces[i])

func spawn_slime():
	if slime_spaces != null:
		for i in slime_spaces.size():
			emit_signal("make_slime", slime_spaces[i])


func match_at(i: int, j: int, color: String) -> bool:
	var adjacent_colors: Array[String] = []

	if i > 0 and all_pieces[i - 1][j] != null:  # Check left
		if all_pieces[i - 1][j].color == color:
			return true
		adjacent_colors.append(all_pieces[i - 1][j].color)

	if i < width - 1 and all_pieces[i + 1][j] != null:  # Check right
		if all_pieces[i + 1][j].color == color:
			return true
		adjacent_colors.append(all_pieces[i + 1][j].color)

	if j > 0 and all_pieces[i][j - 1] != null:  # Check top
		if all_pieces[i][j - 1].color == color:
			return true
		adjacent_colors.append(all_pieces[i][j - 1].color)

	if j < height - 1 and all_pieces[i][j + 1] != null:  # Check bottom
		if all_pieces[i][j + 1].color == color:
			return true
		adjacent_colors.append(all_pieces[i][j + 1].color)

	# Check if any adjacent colors match the current color
	for adj_color in adjacent_colors:
		if adj_color == color:
			return true
	return false

func gridToPixel(column: int, row: int) -> Vector2:
	var new_x = x_start + offset * column
	var new_y = y_start + offset * row
	return Vector2(new_x, new_y)

func pixel_to_grid(pixel_x, pixel_y):
	var new_x = round((pixel_x - x_start) / offset)
	var new_y = round((pixel_y - y_start) / offset)
	return Vector2(new_x, new_y)
	#pass;
# Checks if touch is inside the grid
func is_in_grid(column, row):
	if column >= 0 && column < width:
		if row >= 0 && row < height:
			return true
	return false



func touch_input():
	if Input.is_action_just_pressed("ui_touch"):
		first_touch = get_global_mouse_position();
		var grid_position = pixel_to_grid(first_touch.x, first_touch.y);
		if is_in_grid(grid_position.x, grid_position.y):
			controlling = true
		#else:
		#	print("BAD THING MA G")
	if Input.is_action_just_released("ui_touch"):
		final_touch = get_global_mouse_position();
		var grid_position = pixel_to_grid(final_touch.x, final_touch.y)
		if is_in_grid(grid_position.x, grid_position.y) && controlling:
			touch_difference(pixel_to_grid(first_touch.x, first_touch.y), grid_position)
			controlling = false;

func swap_pieces(column, row, direction):
	var target_column = column + direction.x
	var target_row = row + direction.y
	if is_in_grid(column, row) && is_in_grid(target_column, target_row):
		var first_piece = all_pieces[column][row]
		var other_piece = all_pieces[target_column][target_row]
		if first_piece != null && other_piece != null:
			if !restricted_move(Vector2(column, row)) and !restricted_move(Vector2(column, row) + direction):
				store_info(first_piece, other_piece, Vector2(column, row), direction)  #Stores the piece info in store_info
				state = wait
				all_pieces[column][row] = other_piece
				all_pieces[target_column][target_row] = first_piece
				first_piece.move(gridToPixel(target_column, target_row))
				other_piece.move(gridToPixel(column, row))
				if !move_checked:
					find_matches()
				#state = move

func store_info(first_piece, other_piece, place, direction):
	piece_one = first_piece
	piece_two = other_piece
	last_place = place
	last_direction = direction
	pass

func swap_back():
	print("No Match")
	#Move the previously swapped pieces back to the previous place.
	if piece_one != null && piece_two != null:
		swap_pieces(last_place.x, last_place.y, last_direction)
	state = move
	move_checked = false
	pass

func touch_difference(grid_1, grid_2):
	var difference = grid_2 - grid_1
	if abs(difference.x) > abs(difference.y):
		if difference.x > 0:
			swap_pieces(grid_1.x, grid_1.y, Vector2(1, 0))
		elif difference.x < 0:
			swap_pieces(grid_1.x, grid_1.y, Vector2(-1, 0))
	elif abs(difference.y) > abs(difference.x):
		if difference.y > 0:
			swap_pieces(grid_1.x, grid_1.y, Vector2(0, 1))
		elif difference.y < 0:
			swap_pieces(grid_1.x, grid_1.y, Vector2(0, -1))


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if state == move:
		touch_input();

func find_matches():
	for i in range(width):
		for j in range(height):
			if all_pieces[i][j] != null:
				var current_color = all_pieces[i][j].color
				if i > 0 && i < width - 1:
					if !is_piece_null(i - 1, j) && all_pieces[i + 1][j] != null:
						if all_pieces[i - 1][j].color == current_color && all_pieces[i + 1][j].color == current_color:
							match_and_dim(all_pieces[i - 1][j])
							match_and_dim(all_pieces[i][j])
							match_and_dim(all_pieces[i + 1][j])
							add_to_array(Vector2(i, j))
							add_to_array(Vector2(i + 1, j))
							add_to_array(Vector2(i - 1, j))
				if j > 0 && j < height - 1:
					if all_pieces[i][j - 1] != null && all_pieces[i][j + 1] != null:
						if all_pieces[i][j - 1].color == current_color && all_pieces[i][j + 1].color == current_color:
							match_and_dim(all_pieces[i][j - 1])
							match_and_dim(all_pieces[i][j])
							match_and_dim(all_pieces[i][j + 1])
							add_to_array(Vector2(i, j))
							add_to_array(Vector2(i, j + 1))
							add_to_array(Vector2(i, j - 1))
	get_parent().get_node("destroy_timer").start()
	#if !damaged_slime:
	#	print("SPAWN A SLIME BECAUSE YOU DID NNOOTT BREAK A SLIME1")
	#	generate_slime() # Call generate_slime when no matches are found                     -------- Disable this for no slime spawning // must remove the pre ready slimes also
	#generate_slime() # Call generate_slime after finding matches

func add_to_array(value, array_to_add = current_matches):
	if !array_to_add.has(value):
		array_to_add.append(value)
		

func is_piece_null(column, row):
	if all_pieces[column][row] == null:
		return true
	return false

func match_and_dim(item):
	item.matched = true
	item.dim()

func find_bombs():
	# Iterate over current_matches array
	for i in current_matches.size():
		# Store some values for this match
		var current_column = current_matches[i].x
		var current_row = current_matches[i].y
		var current_color = all_pieces[current_column][current_row].color
		var _matched = 0
		var col_matched = 0
		var row_matched = 0
		# Iterate over the current matches to check for culmn, row, and color
		for j in current_matches.size():
			var this_column = current_matches[j].x
			var this_row = current_matches[j].y
			var this_color = all_pieces[current_column][current_row].color
			if this_column == current_column and current_color == this_color:
				col_matched +=1
			if this_row == current_row and this_color == current_color:
				row_matched +=1
		# 0 is an adj bomb, 1, is a row bomb, and 2 is a column bomb
		# 3 is a color bomb
		if col_matched == 5 or row_matched == 5:
			print("color bomb")
			return
		if col_matched >= 3 and row_matched >= 3:
			make_bomb(0, current_color)
			return
		if col_matched == 4:
			make_bomb(1, current_color)
			return
		if row_matched == 4:
			make_bomb(2, current_color)
			return
	pass

func make_bomb(bomb_type, color):
	# iterate over current_matches
	for i in current_matches.size():
		# cache a few vars 
		var current_column = current_matches[i].x
		var current_row = current_matches[i].y
		if all_pieces[current_column][current_row] == piece_one and piece_one.color == color:
			#Make peice_one a bomb
			piece_one.matched = false
			change_bomb(bomb_type, piece_one)
		if all_pieces[current_column][current_row] == piece_two and piece_two.color == color:
			# Make piece_two a bomb
			piece_two.matched = false
			change_bomb(bomb_type, piece_two)

func change_bomb(bomb_type, piece):
	if bomb_type == 0:
		piece.make_adjacent_bomb()
	elif bomb_type == 1:
		piece.make_row_bomb()
	elif bomb_type == 2:
		piece.make_column_bomb()


func destroy_matched():
	find_bombs()
	var was_matched = false
	for i in width:
		for j in height:
			if all_pieces[i][j] != null:
				if all_pieces[i][j].matched:
					damage_special(i,j)
					was_matched = true
					all_pieces[i][j].queue_free()
					all_pieces[i][j] = null
	move_checked = true
	if was_matched:
		get_parent().get_node("collapse_timer").start()
	else:
		swap_back()
	state = move
	current_matches.clear()

func check_concrete(column, row):
	#check right
	if column < width -1:
		emit_signal("damage_concrete", Vector2(column + 1, row))
		#check left
	if column > 0:
		emit_signal("damage_concrete", Vector2(column - 1, row))
	#check up
	if row < height -1:
		emit_signal("damage_concrete", Vector2(column, row + 1))
		#check up 
	if row > 0:
		emit_signal("damage_concrete", Vector2(column, row - 1))

func check_slime(column, row):
	print("checking all sides of the slime")
	#check right
	if column < width -1:
		emit_signal("damage_slime", Vector2(column + 1, row))
		#check left
	if column > 0:
		emit_signal("damage_slime", Vector2(column - 1, row))
	#check down
	if row < height -1:
		emit_signal("damage_slime", Vector2(column, row + 1))
		#check up 
	if row > 0:
		emit_signal("damage_slime", Vector2(column, row - 1))

func damage_special(column, row):
	emit_signal("damage_ice", Vector2(column, row))
	emit_signal("damage_lock", Vector2(column, row))
	check_concrete(column, row)
	check_slime(column, row)


func collapse_columns():
	for i in range(width):
		for j in range(height - 1, -1, -1):
			if all_pieces[i][j] == null && !restricted_fill(Vector2(i,j)):
				for k in range(j - 1, -1, -1):
					if all_pieces[i][k] != null:
						all_pieces[i][k].move(gridToPixel(i, j))
						all_pieces[i][j] = all_pieces[i][k]
						all_pieces[i][k] = null
						break
	get_parent().get_node("refill_timer").start()


func refill_columns():
	for i in range(width):
		for j in range(height):
			if all_pieces[i][j] == null && !restricted_fill(Vector2(i,j)):
				var rand = randi() % possible_pieces.size()
				var piece_scene = possible_pieces[rand]
				var piece_instance = piece_scene.instantiate()
				var loops = 0
				while (match_at(i, j, piece_instance.color) && loops < 100):
					rand = randi() % possible_pieces.size()
					piece_scene = possible_pieces[rand]
					loops += 1
					piece_instance = piece_scene.instantiate()
				if piece_scene and piece_instance:
					add_child(piece_instance)
					piece_instance.position = gridToPixel(i, j - y_offset)
					piece_instance.move(gridToPixel(i,j))
					all_pieces[i][j] = piece_instance
	after_refill()

func after_refill():
	for i in range(width):
		for j in range(height):
			if all_pieces[i][j] != null:
				if match_at(i, j, all_pieces[i][j].color):
					find_matches()
					get_parent().get_node("destroy_timer").start()
					return
	if not damaged_slime:
		print("SPAWN A SLIME BECAUSE YOU DID NNOOTT BREAK A SLIME")
		generate_slime() # Call generate_slime when no matches are found
	state = move
	move_checked = false
	damaged_slime = false


func generate_slime():
	# Make sure there are slime spaces on the board
	if slime_spaces.size() > 0:
		var slime_made = false
		var tracker = 0
		while !slime_made && tracker < 100:
			# Check a random slime space
			var random_num = randi() % slime_spaces.size()
			var curr_x = slime_spaces[random_num].x
			var curr_y = slime_spaces[random_num].y
			var neighbor = find_normal_neighbor(curr_x, curr_y)
			if neighbor != null:
				# Turn the neighbor into a slime
				# Remove the piece
				all_pieces[neighbor.x][neighbor.y].queue_free()
				# Set it to null
				all_pieces[neighbor.x][neighbor.y] = null
				# Add the new spot to the array of slimes
				slime_spaces.append(Vector2(neighbor.x, neighbor.y))
				# Send a signal to the slime holder to make a new slime
				emit_signal("make_slime", Vector2(neighbor.x, neighbor.y))
				slime_made = true
			tracker += 1


func find_normal_neighbor(column, row):
	# Check Right first
	if is_in_grid(column + 1, row):
		if all_pieces[column + 1][row] != null:
			return Vector2(column + 1, row)
	# Check Left
	elif is_in_grid(column - 1, row):
		if all_pieces[column - 1][row] != null:
			return Vector2(column - 1, row)
	# Check up
	elif is_in_grid(column, row + 1):
		if all_pieces[column][row + 1] != null:
			return Vector2(column, row + 1)
	# Check Down
	elif is_in_grid(column, row - 1):
		if all_pieces[column][row - 1] != null:
			return Vector2(column, row - 1)
	return null


func _on_destroy_timer_timeout():
	destroy_matched()

func _on_collapse_timer_timeout():
	collapse_columns()

func _on_refill_timer_timeout():
	refill_columns()

func _on_lock_holder_remove_lock(place):
	for i in range(lock_spaces.size() - 1, -1, -1):
		if lock_spaces[i] == place:
			lock_spaces.remove_at(i)

func _on_concrete_holder_remove_concrete(place):
	for i in range(concrete_spaces.size() - 1, -1, -1):
		if concrete_spaces[i] == place:
			concrete_spaces.remove_at(i)


func _on_slime_holder_remove_slime(place):
	damaged_slime = true
	for i in range(slime_spaces.size() - 1, -1, -1):
		if slime_spaces[i] == place:
			slime_spaces.remove_at(i)

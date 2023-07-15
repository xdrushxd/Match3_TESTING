extends Node2D

signal remove_lock

var lock_pieces = []
var width = 8
var height = 10
var licorice = preload("res://scenes/licorice.tscn")


# Called when the node enters the scene tree for the first time.
func _ready():
	
	pass # Replace with function body.

func makeGrid() -> Array:
	var grid: Array = []
	for i in range(width):
		var row: Array = []
		for j in range(height):
			row.append(null)
		grid.append(row)
	return grid

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_grid_make_lock(board_position):
	if lock_pieces.size() == 0:
		lock_pieces = makeGrid()
	var current = licorice.instantiate()
	add_child(current)
	current.position = Vector2(board_position.x * 64 + 64, board_position.y * 64 + 250)
	lock_pieces[board_position.x][board_position.y] = current


func _on_grid_damage_lock(board_position):
	if lock_pieces[board_position.x][board_position.y] != null:
		lock_pieces[board_position.x][board_position.y].take_damage(1)
		if lock_pieces[board_position.x][board_position.y].health <= 0:
			lock_pieces[board_position.x][board_position.y].queue_free()
			lock_pieces[board_position.x][board_position.y] = null
			emit_signal("remove_lock", board_position)

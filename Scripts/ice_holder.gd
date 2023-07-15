extends Node2D

var ice_pieces = []
var width = 8
var height = 10
var ice = preload("res://scenes/ice.tscn")


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



func _on_grid_make_ice(board_position):
	if ice_pieces.size() == 0:
		ice_pieces = makeGrid()
	var current = ice.instantiate()
	add_child(current)
	current.position = Vector2(board_position.x * 64 + 64, board_position.y * 64 + 250)
	ice_pieces[board_position.x][board_position.y] = current


func _on_grid_damage_ice(board_position):
	if ice_pieces[board_position.x][board_position.y] != null:
		ice_pieces[board_position.x][board_position.y].take_damage(1)
		if ice_pieces[board_position.x][board_position.y].health <= 0:
			ice_pieces[board_position.x][board_position.y].queue_free()
			ice_pieces[board_position.x][board_position.y] = null
	pass # Replace with function body.

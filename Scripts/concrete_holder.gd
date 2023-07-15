extends Node2D

signal remove_concrete

var concrete_pieces = []
var width = 8
var height = 10
var concrete = preload("res://scenes/concrete.tscn")


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

func _on_grid_make_concrete(board_position):
	if concrete_pieces.size() == 0:
		concrete_pieces = makeGrid()
	var current = concrete.instantiate()
	add_child(current)
	current.position = Vector2(board_position.x * 64 + 64, board_position.y * 64 + 250)
	concrete_pieces[board_position.x][board_position.y] = current


func _on_grid_damage_concrete(board_position):
	if concrete_pieces[board_position.x][board_position.y] != null:
		concrete_pieces[board_position.x][board_position.y].take_damage(1)
		if concrete_pieces[board_position.x][board_position.y].health <= 0:
			concrete_pieces[board_position.x][board_position.y].queue_free()
			concrete_pieces[board_position.x][board_position.y] = null
			emit_signal("remove_concrete", board_position)

extends Node2D

@export var color = "";
@export row_texture var (Texture)
@export column_texture var (Texture)
@export adjacent_texture var (Texture)

var is_row_bomb = false
var is_column_bomb = false
var is_adjacent_bomb = false

var move_tween;
var matched = false;


func _ready():
	pass # Replace with function body.

func move(target):
	var tween: Tween = create_tween()
	tween.tween_property(self,"position",target, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	#move_tween.start()
	#Ier bove da breekt de code ma kan nog vanpas komen 

func make_column_bomb():
	is_column_bomb = true
	$Sprite.texture = column_texture
	$Sprite.modulate = Color(1, 1, 1, 1)

func make_row_bomb():
	is_row_bomb = true
	$Sprite.texture = row_texture
	$Sprite.modulate = Color(1, 1, 1, 1)

func make_adjacent_bomb():
	is_adjacent_bomb = true
	$Sprite.texture = adjacent_texture
	$Sprite.modulate = Color(1, 1, 1, 1)

func dim():
	var sprite = get_node("Sprite")
	sprite.modulate = Color(color) * Color(1, 1, 1, 0.5)

extends Node2D

@export var health: int

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.




func take_damage( damage):
	health -= damage
	# Can add damage effect here // explosion ofzo gelijk nen grote boem

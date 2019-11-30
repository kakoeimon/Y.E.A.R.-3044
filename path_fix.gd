extends Path

# Declare member variables here. Examples:
# var a = 2
# var b = "text"
onready var new_curve = $Path.curve

# Called when the node enters the scene tree for the first time.
func _ready():
	print(curve.get_point_count())
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

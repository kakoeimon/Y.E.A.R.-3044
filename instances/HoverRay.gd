extends RayCast

var user : RigidBody = null
# Called when the node enters the scene tree for the first time.
func _ready():
	var parent = get_parent()
	if parent is RigidBody:
		user = parent
		exclude_parent = true
	pass # Replace with function body.

#func _physics_process(delta):
#	if is_colliding():
#		var p = get_collision_point()
#		var dis = p - global_transform.origin
#		var d = cast_to.length() - dis.length()
#		user.add_force(Vector3(0,d,0) * 100 , Vector3.ZERO)
		


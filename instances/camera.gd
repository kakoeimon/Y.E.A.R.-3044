extends Camera


var cam_speed = 10
var id = 1
var target_weakref : WeakRef = null
# Called when the node enters the scene tree for the first time.
func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	pass # Replace with function body.

func _physics_process(delta):
	if target_weakref:
		var target = target_weakref.get_ref()
		if target and not target.is_queued_for_deletion():
			global_transform.origin = global_transform.origin.linear_interpolate(target.cam_target.global_transform.origin, cam_speed * delta)
			look_at(target.cam_look.global_transform.origin, target.global_transform.basis.y)
		
			$Control/Velocity.text = str(int(target.linear_velocity.length()))
			var _c = target.boost_capacity
			$Control/BoostBar.value = _c
			if _c <= 0:
				$Control/BoostBar/Danger.show()
			else:
				$Control/BoostBar/Danger.hide()
				
			if target.action_boost_pressed:
				$Control/BoostBar/Boost.show()
			else:
				$Control/BoostBar/Boost.hide()

extends RigidBody

var gles3 = OS.get_current_video_driver() == OS.VIDEO_DRIVER_GLES3

var is_player = false
var joynum = -1

onready var gravity_ray = $GravityRay
onready var hover_ray = $HoverRay1
onready var cam_look = $CamLook
onready var cam_target = $CamLook/CamTarget
var turbine_particles
var turbine_particles2
var hover_particles

var can_move = false #This exists so we can have a timer in the begining of the race

var camera : Camera
var cam_speed : float = 10.0

var number = 1 #Thsi is going to be used for the action names

var position = 0

var fake_position = 1 #This will be updated By the FakePositionTimer it is used by ai so it can boost in the first place

var progress : float = 0.0 #The progress in the current lap 

var t : float = 0.0 #The actual offset on the curve
var road_path : Curve3D

#Last Valid Transform
var last_valid_transform : Transform
var last_valid_transform_back : Transform
var last_valid_transform_t : float = 0
var last_valid_transform_dis : float = 40
var last_valid_transform_col : bool = false

var lap = 1

var default_cam_look : Quat

var mouse_sensitivity : float = 0.01

var gravity_force : float = 16000.0

const max_speed_const : float = 75.0
var max_speed : float = max_speed_const

const acc_const : float = 16000.0

var brake : float = 5000.0

const turn_speed_const : float = 12.5

var hover_force : float = 10500.0

var cam_look_timer : float = 0

var boost_max_capacity = 20.0
var boost_min_capacity = -10.0
var boost_capacity = boost_max_capacity
var boost_reload_time : float = 1.0
var boost_reload_counter : float = 0.0
var boost_reload_rate : float = 10.0
var boost_use_rate : float = 10.0



var _no_hover_ray_counter : int = 0
const _no_hover_ray_time : int = 150


var action_acc = "Acceleration"
var action_acc_pressed : float = 0.0
var action_steer_left = "SteerLeft"
var action_steer_right = "SteerRight"
var action_steer = 0.0
var action_boost = "Boost"
var action_boost_pressed = false
var action_boost_just_released = false
var action_break = "Break"
var action_break_pressed = false

# Called when the node enters the scene tree for the first time.
func _ready():
	action_acc += str(number)
	action_steer_left += str(number)
	action_steer_right += str(number)
	action_boost += str(number)
	action_break += str(number)
	
	default_cam_look = Quat(cam_look.transform.basis)
	
	$mesh/mesh.set_surface_material(1, preload("res://models/ShipColor.material").duplicate())
	$mesh/mesh.get_surface_material(1).albedo_color = get_parent().get_parent().player_colors[number - 1]
	
	if not is_player: $FakePositionTimer.start()
	
	if joynum == -1: set_process_input(false)
	
	road_path = get_parent().get_parent().road_path
	last_valid_transform = global_transform
	
	if gles3:
		turbine_particles = $TurbineParticles
		turbine_particles2 = $TurbineParticles2
		
		turbine_particles.process_material = turbine_particles.process_material.duplicate()
		$TurbineParticles2.process_material = turbine_particles.process_material
		
		hover_particles = $HoverParticles
		hover_particles.process_material = hover_particles.process_material.duplicate()
		$CPUHoverParticles.queue_free()
		$CPUTurbineParticles.queue_free()
		$CPUTurbineParticles2.queue_free()
	else:
		turbine_particles = $CPUTurbineParticles
		turbine_particles2 = $CPUTurbineParticles2
		hover_particles = $CPUHoverParticles
		$HoverParticles.queue_free()
		$TurbineParticles.queue_free()
		$TurbineParticles2.queue_free()
		
	pass # Replace with function body.

func _physics_process(delta):
	align_to_ray(gravity_ray)
	
	camera_update(delta)
	if Input.is_joy_button_pressed(joynum, 9): camera.rotate(global_transform.basis.y, PI)
	#PROGRESS
	var new_t = road_path.get_closest_offset(translation)
	var end = road_path.get_baked_length()
	if new_t > t:
		if hover_ray.is_colliding(): 
			progress = new_t
	if progress > end / 1.5: #Just big enough to know that you a re not tricking it over the starting position
		if new_t < end / 4: #Just big enough but smaller for the previous
			lap += 1
			progress = new_t
			last_valid_transform = global_transform
			last_valid_transform.origin = road_path.interpolate_baked(5)
			if lap > get_parent().get_parent().laps:
				if camera.get_node("Control").visible:
					is_player = false
					camera.get_node("Control").hide()
					camera.get_node("Finish").show()
					camera.get_node("Finish/%s" % str(position)).show()
	t = new_t
	
	var new_engine_pitch = linear_velocity.length() / max_speed_const
	if new_engine_pitch < 0.5: new_engine_pitch = 0.5
	$AudioEngine.pitch_scale = lerp($AudioEngine.pitch_scale, new_engine_pitch, delta)
	#print(new_engine_pitch)
	if gles3:
		turbine_particles.process_material.gravity.z = linear_velocity.length() * 5
	else:
		turbine_particles.gravity.z = linear_velocity.length() * 5
		turbine_particles2.gravity.z = turbine_particles.gravity.z
	
	
	if gles3:
		var hover_scale = hover_particles.process_material.scale
		var hover_scale_ray = hover_ray.cast_to.y
		if boost_capacity >= 0:
			hover_particles.process_material.scale = lerp(hover_scale, hover_scale_ray, 0.1)
			hover_particles.local_coords = true
		else:
			
			hover_particles.process_material.scale = lerp(hover_scale, hover_scale_ray + (abs(boost_capacity) + 1) * 2 , 0.5)
			hover_particles.local_coords = false
	else:
		var hover_scale = hover_particles.scale_amount
		var hover_scale_ray = hover_ray.cast_to.y
		if boost_capacity >= 0:
			hover_particles.scale_amount = lerp(hover_scale, hover_scale_ray, 0.1)
			hover_particles.local_coords = true
		else:
			hover_particles.scale_amount = lerp(hover_scale, hover_scale_ray + (abs(boost_capacity) + 1) * 1.0 , 0.5)
			hover_particles.local_coords = false
	

	
func _integrate_forces(state):
	var delta = state.step 
	var acc = acc_const
	var turn_speed = turn_speed_const
	var max_speed = max_speed_const
	
	##### Manage Input
	if can_move:
		if is_player:
			get_player_input(delta)
		else:
			get_ai_input(delta)
	hover(state, hover_ray)
	
	if !hover_ray.is_colliding():
		acc /=2
		_no_hover_ray_counter +=1
		if gles3:
			hover_particles.process_material.damping = 100
		else:
			hover_particles.damping = 100
		if _no_hover_ray_counter > _no_hover_ray_time:
			die()
	else:
		_no_hover_ray_counter = 0
		if gles3:
			hover_particles.process_material.damping = 0
		else:
			hover_particles.damping = 0


	

	var gravity = -get_transform().basis.y * gravity_force * delta

	add_central_force(gravity)
	
	if action_boost_just_released:
		if boost_capacity > 0:
			boost_reload_counter = 0.0
		
	if action_boost_pressed:
		if boost_capacity > boost_min_capacity:
			if gles3:
				turbine_particles.process_material.scale = lerp(turbine_particles.process_material.scale, 2, 0.3)
				turbine_particles.lifetime = 0.12
				turbine_particles2.lifetime = turbine_particles.lifetime
			else:
				turbine_particles.scale_amount = lerp(turbine_particles.scale_amount, 2, 0.3)
				turbine_particles2.scale_amount = turbine_particles.scale_amount
				turbine_particles.lifetime = 0.12
				turbine_particles2.lifetime = 0.12
			boost_capacity -= boost_use_rate * delta
			add_central_force(-transform.basis.z * acc * delta * 0.5)
			max_speed *=1.5
			turn_speed *=2
			if boost_capacity < 0.0:
				boost_reload_counter -= delta
		else:
			action_steer = 0.0
			can_move = false
			$BoostPenaltyTimer.start()
	else:
		if gles3:
			turbine_particles.process_material.scale = lerp(turbine_particles.process_material.scale, 1, 0.1)
			turbine_particles.lifetime = 0.1
			turbine_particles2.lifetime = 0.1
		else:
			turbine_particles.scale_amount = lerp(turbine_particles.scale_amount, 1, 0.1)
			turbine_particles2.scale_amount = turbine_particles.scale_amount
			turbine_particles.lifetime = 0.1
			turbine_particles2.lifetime = 0.1
		boost_reload_counter += delta
		if boost_reload_counter >= boost_reload_time:
			boost_capacity += boost_reload_rate * delta
			if boost_capacity > boost_max_capacity:
				boost_capacity = boost_max_capacity
				
	#print(boost_capacity)
	
	
	if action_acc_pressed > 0.01:
		add_central_force(-transform.basis.z * acc * delta)
		
	if action_break_pressed:
		add_central_force(transform.basis.z * brake * delta)
		
	if abs(action_steer) > 0.01:
		q_rot(-get_transform().basis.y, turn_speed * delta * action_steer)
	
	if linear_velocity.length() > max_speed:
		linear_velocity = linear_velocity.normalized() * max_speed
	
	get_last_valid_transform()

func align_to_ray(gray : RayCast):
	if gray.is_colliding():
		var n1 = transform.basis.y.normalized()
		var n2 = gray.get_collision_normal().normalized()
		
		var cosa = n1.dot(n2)
		
		var alpha = acos(cosa)
		
		var axis = n1.cross(n2)
		axis = axis.normalized()
		if !is_nan(alpha):
			#rotate(axis, alpha)
			q_rot(axis, alpha, 0.1)
	else:
		#WARNING This way we make sure that we set the transformation
		var o = transform.origin
		transform = Transform(Quat(transform.basis))
		transform.origin = o

func normal_align(n : Vector3):
	var n1 = transform.basis.y.normalized()
	
	var cosa = n1.dot(n)
	
	var alpha = acos(cosa)
	
	var axis = n1.cross(n)
	axis = axis.normalized()
	if !is_nan(alpha):
		#rotate(axis, alpha)
		q_rot(axis, alpha, 1)

func q_rot(axis : Vector3, value : float, w : float = 0.1):
	var q1 = Quat(transform.rotated(axis, value).basis)
	var q2 = Quat(transform.basis)
	var o = transform.origin
	
	transform = Transform(q2.slerp(q1, w))
	transform.origin = o
	
		
func hover(state: PhysicsDirectBodyState, hray: RayCast):
	if hray.is_colliding():
		var l = (hray.global_transform.origin - hray.get_collision_point()).length()
		var d = hray.cast_to.length() / l
		var force = global_transform.basis.y * hover_force  * state.step
		force = lerp(global_transform.basis.y, force, d)
		
		state.add_central_force(force)
		return true
	return false
	

func get_player_input(delta : float):
	if joynum !=-1:
		action_acc_pressed = Input.is_joy_button_pressed(joynum, 7)
		action_boost_pressed =  Input.is_joy_button_pressed(joynum, 6)
		action_boost_just_released = Input.is_joy_button_pressed(joynum, 6)
		action_steer = Input.get_joy_axis(joynum, 0)
		action_break_pressed = Input.is_joy_button_pressed(joynum, 5)
		
	else:
		action_acc_pressed = float(Input.is_action_pressed(action_acc))
		action_boost_pressed = Input.is_action_pressed(action_boost)
		action_boost_just_released = Input.is_action_just_released(action_boost)
		if Input.is_action_pressed(action_steer_left): 
			action_steer = -1.0
		elif Input.is_action_pressed(action_steer_right):
			action_steer = 1.0
		else:
			action_steer = 0.0
		action_break_pressed = Input.is_action_pressed(action_break)

func _input(event):
	if event is InputEventMouseMotion:
		cam_look_timer = 1
		var rel = event.relative * mouse_sensitivity
		cam_look.rotate_y(rel.x)
		cam_look.rotate_x(rel.y)

func get_ai_input(delta : float):
	var space = get_world().direct_space_state
	var players = get_parent().get_parent().players
	var end = road_path.get_baked_length()
	var new_t = t + 10.0
	if new_t >= end: new_t -= end
	var target_pos = road_path.interpolate_baked(t + 10.0)
	var velocity = linear_velocity.length()
	
	
	action_acc_pressed = true
	action_steer = 0.0
	action_boost_just_released = false
	
	
	########### "Change Lane" when infront of you there is a player 
	for i in range(players.size()):
		if i != number - 1:
			var t_p = road_path.get_closest_offset(players[i].translation)
			if t_p > t:
				var _dis = t_p - t
					
				if _dis < 10:
					var p_n = players[i].translation - translation
					var p_dot = global_transform.basis.x.dot(p_n)
					if p_dot < 0:
						target_pos +=global_transform.basis.x * max_speed_const  * delta
					else:
						target_pos -=global_transform.basis.x * max_speed_const  * delta
						
	########### BOOST
	################Boost on stiff turns
	if hover_ray.is_colliding():
		var distance = (target_pos - translation)#.normalized()
		
		var a = global_transform.basis.x.dot(distance)
		if abs(a) > 0.1:
			action_steer = a
		
	if abs(action_steer) > 1 and boost_capacity > 0:
		action_boost_pressed = true
		action_steer /= abs(action_steer)
	else:
		##########Boost when it is clear
		if hover_ray.is_colliding() and fake_position != 1:
			var pos_to_boost = road_path.interpolate_baked(t + 100)
			pos_to_boost += global_transform.basis.y * 1
			var col = space.intersect_ray(translation, pos_to_boost, players)
			if col.empty() and boost_capacity > boost_max_capacity / 3:
				action_boost_pressed = true
			elif action_boost_pressed:
				action_boost_pressed = false
				action_boost_just_released = true
		elif action_boost_pressed:
			action_boost_pressed = false
			action_boost_just_released = true
	
#	print(action_steer)
#	print(a)
#	print(t)
	
func die():
	action_steer = 0.0
	can_move = false
	linear_velocity = Vector3()
	
	global_transform = last_valid_transform
	_on_BoostPenaltyTimer_timeout()
	
func _on_HoverCraft_body_entered(body):
	if not gravity_ray.is_colliding():
		die()
	pass # Replace with function body.

func camera_update(delta : float):
	#if not camera: return
	if cam_look_timer <=0:
		cam_look.transform = Transform(Quat(cam_look.transform.basis).slerp(default_cam_look, 0.1))
	else:
		cam_look_timer -=delta
	
	camera.global_transform.origin = camera.global_transform.origin.linear_interpolate(cam_target.global_transform.origin, cam_speed * delta)
	camera.look_at(cam_look.global_transform.origin, global_transform.basis.y)

	camera.get_node("Control/Velocity").value = linear_velocity.length()
	camera.get_node("Control/Velocity2").value = linear_velocity.length()

	camera.get_node("Control/BoostBar").value = boost_capacity
	if boost_capacity <= 0:
		camera.get_node("Control/BoostBar/Danger").show()
	else:
		camera.get_node("Control/BoostBar/Danger").hide()
		
	if action_boost_pressed:
		camera.get_node("Control/BoostBar/Boost").show()
	else:
		camera.get_node("Control/BoostBar/Boost").hide()
		
	camera.get_node("Control/Lap/CurrentLap").text = str(lap)
	camera.get_node("Control/Position/TargetPosition").text = str(position)

func _on_FakePositionTimer_timeout():
	fake_position = position
	pass # Replace with function body.


func _on_BoostPenaltyTimer_timeout():
	can_move = true
	pass # Replace with function body.


func get_last_valid_transform():
	if hover_ray.is_colliding():
		if last_valid_transform_col:
			if t - last_valid_transform_t >= last_valid_transform_dis:
				last_valid_transform_t = t
				last_valid_transform = last_valid_transform_back
				last_valid_transform_back = global_transform
		else:
			last_valid_transform_t = t
			last_valid_transform_col = true
			last_valid_transform_back = global_transform
	else:
		last_valid_transform_col = false
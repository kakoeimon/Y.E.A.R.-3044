extends Spatial

const player_pck = preload("res://instances/hovercraft_2.tscn")
onready var track = $Track
onready var road_path : Curve3D = get_node("RoadPath").get_child(0).curve
var number_of_players = 4
var number_of_humans_players = 1

var players = []

# Called when the node enters the scene tree for the first time.
func _ready():
	road_path.bake_interval = 10
	_add_players(number_of_players)
	
	
	

	print(road_path.get_baked_length())
	print(road_path.get_baked_points().size())
	print(road_path.get_point_count())
	print(road_path.bake_interval)


#	var time = OS.get_ticks_msec()
#	for i in range(1000):
#		road_path.get_closest_point(Vector3(randi()%5000, randi()%5000, randi()%5000))
#	print(OS.get_ticks_msec() - time)
	pass # Replace with function body.

func _add_players(n):
	if n <= 0: return
	 
	for i in range(n):
		var p = player_pck.instance()
		p.number = i + 1
		if i < number_of_humans_players:
			_add_camera(p)
			p.is_player = true
			
			
		players.push_back(p)
		add_child(p)
		if n == 1:
			p.transform = $Track/Spawn0.transform
		else:
			p.transform = get_node("Track/Spawn%s" % (i + 1)).transform
		
		
		
	
	
func _add_camera(p):
	var camera = preload("res://instances/camera.tscn").instance()
	add_child(camera)
	camera.transform = p.transform
	camera.target_weakref = weakref(p)
	

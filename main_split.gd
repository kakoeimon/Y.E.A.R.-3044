extends Node2D

const player_pck = preload("res://instances/hovercraft_2.tscn")

var tracks_paths = ["res://tracks/track_6.tscn", "res://tracks/track_1.tscn", "res://tracks/track_2.tscn", "res://tracks/track_7.tscn"]
var track_pos = 0

var track
 
#var road_path : Curve3D = get_node("Track/RoadPath").get_child(0).curve
var road_path : Curve3D

var number_of_players = 4
var number_of_humans_players = 1
var laps = 3

var players = []

var players_in_position_order = []

var player_colors = [Color.red, Color.blue, Color.green, Color.cornsilk]

#### Shorter Class to be used with players_in_position_order in _short_players_position 
########to add the position of the players
class PositionSorter:
	static func sort(a, b):
		if a.lap >= b.lap and a.t >= b.t:
			return true
		return false
		
# Called when the node enters the scene tree for the first time.
func _ready():
	load_settings()
	change_track(0)
	if not Input.is_joy_known(0):
		$MainMenu/Keyboard.pressed = true
	
	var v = OS.get_current_video_driver()
	
	
func _physics_process(delta):
	_short_players_position()
	if Input.is_action_just_pressed("StartButton"):
		if $MainMenu.visible:
			_on_StartButton_pressed()
		elif $PauseMenu.visible:
			_on_ResumeButton_pressed()
		else:
			get_tree().paused = true
			$PauseMenu.visible = true
			show_submenu(true)
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			
		
	pass

func _add_players(n):
	if n <= 0: return
	 
	for i in range(n):
		var p = player_pck.instance()
		
		
		p.number = i + 1
		if i < number_of_humans_players:
			p.is_player = true
			
			
		if i == 0:
			$Viewport1/Camera.transform = p.transform
			p.camera = $Viewport1/Camera
		elif i == 1:
			$Viewport2/Camera.transform = p.transform
			p.camera = $Viewport2/Camera
		elif i == 2:
			$Viewport3/Camera.transform = p.transform
			p.camera = $Viewport3/Camera
		elif i == 3:
			$Viewport4/Camera.transform = p.transform
			p.camera = $Viewport4/Camera
				
		players.push_back(p)
		
		if n == 1:
			p.transform = $start/Spawn0.global_transform
		else:
			p.transform = get_node("start/Spawn%s" % (i + 1)).transform
			
		track.add_child(p)
		p.camera.get_node("Control/Lap/TotalLaps").text = str(laps)
		p.camera.get_node("Control/Position/NumOfPlayers").text = str(number_of_players)
		
	
func _set_number_of_screens(n):
	var screen_size = Vector2(1280, 720)
	if n == 1:
		$Viewport1.size = screen_size
		$Screen1.position = Vector2()
		$Screen1.show()
		$Screen2.hide()
		$Screen3.hide()
		$Screen4.hide()
		$Viewport1.audio_listener_enable_3d = true
	elif n == 2:
		screen_size.y /= 2
		$Viewport1.size = screen_size
		$Screen1.position = Vector2()
		$Screen1.show()
		$Viewport2.size = screen_size
		$Screen2.position = Vector2(0, screen_size.y)
		$Screen2.show()
		$Screen3.hide()
		$Screen4.hide()
		$Viewport1.audio_listener_enable_3d = true
		$Viewport2.audio_listener_enable_3d = true
	elif n == 3:
		screen_size /= 2
		$Viewport1.size = screen_size
		$Screen1.position = Vector2()
		$Screen1.show()
		$Viewport2.size = screen_size
		$Screen2.position = Vector2(screen_size.x, 0)
		$Screen2.show()
		$Viewport3.size = screen_size
		$Screen3.position = Vector2(screen_size.x / 2, screen_size.y)
		$Screen3.show()
		$Screen4.hide()
		$Viewport1.audio_listener_enable_3d = true
		$Viewport2.audio_listener_enable_3d = true
		$Viewport3.audio_listener_enable_3d = true
		
	elif n == 4:
		screen_size /= 2
		$Viewport1.size = screen_size
		$Screen1.position = Vector2()
		$Screen1.show()
		$Viewport2.size = screen_size
		$Screen2.position = Vector2(screen_size.x, 0)
		$Screen2.show()
		$Viewport3.size = screen_size
		$Screen3.position = Vector2(0, screen_size.y)
		$Screen3.show()
		$Viewport4.size = screen_size
		$Screen4.position = screen_size
		$Screen4.show()
		$Viewport1.audio_listener_enable_3d = true
		$Viewport2.audio_listener_enable_3d = true
		$Viewport3.audio_listener_enable_3d = true
		$Viewport4.audio_listener_enable_3d = true
		
func _short_players_position():
	if players_in_position_order.size():
		players_in_position_order.sort_custom( PositionSorter, "sort")
		for i in range(players_in_position_order.size()):
			players_in_position_order[i].position = i + 1
		pass


func _on_Timer_timeout():
	for p in players:
		p.can_move = true
	pass # Replace with function body.

func empty_preview():
	for i in range($MainMenu/PreviewViewport.get_child_count()):
		$MainMenu/PreviewViewport.get_child(i).queue_free()

func change_track(n : int):
	if n > 0:
		track_pos +=1
		if track_pos >= tracks_paths.size():
			track_pos = 0
			
	if n < 0:
		track_pos -=1
		if track_pos < 0:
			track_pos = tracks_paths.size() - 1
	
	empty_preview()
		
	$MainMenu/PreviewViewport.add_child(load(tracks_paths[track_pos]).instance())
	
func _on_Next_pressed():
	change_track(1)
	pass # Replace with function body.

func _on_Previous_pressed():
	change_track(-1)
	pass # Replace with function body.


func _on_StartButton_pressed():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	empty_preview()
	$MainMenu.hide()
	show_submenu(false)
	track = load(tracks_paths[track_pos]).instance()
	road_path = track.get_node("RoadPath").get_child(0).curve
	add_child(track)
	if not $Shadows/ShadowHSlider.value:
		track.get_node("DirectionalLight").shadow_enabled = false
	road_path.bake_interval = 10
	if OS.get_current_video_driver() == OS.VIDEO_DRIVER_GLES2:
		var be = track.get_node("WorldEnvironment").environment.background_energy * 1.2
		track.get_node("WorldEnvironment").environment.background_energy = min(be, 2.0)
	laps = $MainMenu/Laps/OptionButton.get_selected_id()
	number_of_humans_players = $MainMenu/NumPlayers/OptionButton.get_selected_id()
	if $MainMenu/Bots.pressed:
		number_of_players = 4
	else:
		number_of_players = number_of_humans_players
		if number_of_humans_players == 0:
			number_of_players = 4
	_add_players(number_of_players)
	for p in players:
		players_in_position_order.push_back(p)
		p.camera.get_node("Control/Counter/AnimationPlayer").play("count")
	_short_players_position()
	_set_number_of_screens(number_of_humans_players)
	if number_of_humans_players == 0:
		_set_number_of_screens(1)
	if $MainMenu/Keyboard.pressed:
		players[0].joynum = -1
		for i in range(1, players.size()):
			players[i].joynum = i - 1
	else:
		for i in range(0, players.size()):
			players[i].joynum = i
	
	$StartTimer.start()
	$MainMenu/MainViewport.get_child(0).queue_free()
	pass # Replace with function body.




func _on_ResumeButton_pressed():
	$PauseMenu.hide()
	show_submenu(false)
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	pass # Replace with function body.


func _on_ReturnMainButton_pressed():
	players = []
	players_in_position_order = []
	$PauseMenu.hide()
	get_tree().paused = false
	$MainMenu.show()
	track.queue_free()
	track = null
	$Screen1.hide()
	$Screen2.hide()
	$Screen3.hide()
	$Screen4.hide()
	change_track(0)
	$MainMenu/MainViewport.add_child(load("res://main_menu_screen.tscn").instance())
	
	
	pass # Replace with function body.


func _on_SoundHSlider_value_changed(value):
	var volume = (value - 80) / 2
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), volume)
	pass # Replace with function body.


func _on_ShadowHSlider_value_changed(value):
	if value != 0:
		#print(ProjectSettings.get("rendering/quality/shadows/filter_mode"))
		ProjectSettings.set("rendering/quality/shadows/filter_mode", value - 1)
		if track:
			track.get_node("DirectionalLight").shadow_enabled = true
	else:
		ProjectSettings.set("rendering/quality/shadows/filter_mode", value)
		if track:
			track.get_node("DirectionalLight").shadow_enabled = false
	pass # Replace with function body.

func _on_AntialiasingHSlider_value_changed(value):
	$Viewport1.msaa = value
	$Viewport2.msaa = value
	$Viewport3.msaa = value
	$Viewport4.msaa = value


func _on_ExitButton_pressed():
	save_settings()
	get_tree().quit()
	pass # Replace with function body.



func _on_DrawDistanceHSlider_value_changed(value):
	$Viewport1/Camera.far = value
	$Viewport2/Camera.far = value
	$Viewport3/Camera.far = value
	$Viewport4/Camera.far = value
	pass # Replace with function body.

func show_submenu(visibility : bool):
	$SoundVolume.visible = visibility
	$Shadows.visible = visibility
	$Antialiasing.visible = visibility
	$DrawDistance.visible = visibility
	save_settings()
	
func save_settings():
	var save_game = File.new()
	save_game.open("user://settings.save", File.WRITE)
	var save_dict = {
		"sound_volume" : $SoundVolume/SoundHSlider.value,
		"shadows" : $Shadows/ShadowHSlider.value,
		"antialiasing" : $Antialiasing/AntialiasingHSlider.value,
		"draw_distance" : $DrawDistance/DrawDistanceHSlider.value,
		"bots" : $MainMenu/Bots.pressed,
		"keyboard" : $MainMenu/Keyboard.pressed,
		"laps" : $MainMenu/Laps/OptionButton.get_selected_id(),
		"num_players" : $MainMenu/NumPlayers/OptionButton.get_selected_id()
	}
	save_game.store_line(to_json(save_dict))
	save_game.close()
	
func load_settings():
	var save_game = File.new()
	if not save_game.file_exists("user://settings.save"):
		if OS.get_current_video_driver() == OS.VIDEO_DRIVER_GLES2:
			$Shadows/ShadowHSlider.value = 0
			$Antialiasing/AntialiasingHSlider.value = 0
		else:
			$Shadows/ShadowHSlider.value = 2
			$Antialiasing/AntialiasingHSlider.value = 1
		return
	
	save_game.open("user://settings.save", File.READ)
	var settings = parse_json(save_game.get_line())
	$SoundVolume/SoundHSlider.value = settings["sound_volume"]
	_on_SoundHSlider_value_changed($SoundVolume/SoundHSlider.value)
	$Shadows/ShadowHSlider.value = settings["shadows"]
	_on_ShadowHSlider_value_changed($Shadows/ShadowHSlider.value)
	$Antialiasing/AntialiasingHSlider.value = settings["antialiasing"]
	_on_AntialiasingHSlider_value_changed($Antialiasing/AntialiasingHSlider.value)
	$DrawDistance/DrawDistanceHSlider.value = settings["draw_distance"]
	_on_DrawDistanceHSlider_value_changed($DrawDistance/DrawDistanceHSlider.value)
	$MainMenu/Bots.pressed = settings["bots"]
	$MainMenu/Keyboard.pressed = settings["keyboard"]
	$MainMenu/Laps/OptionButton.select( settings["laps"] - 1 )
	$MainMenu/NumPlayers/OptionButton.select( settings["num_players"])
	save_game.close()
	
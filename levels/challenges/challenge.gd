extends Node2D

var stats = Stats
var steam = GlobalSteam
var sounds = Sounds
var global_timer = GlobalTimer

@export var level_id = "challenge_1"
@export var spawn_point = Vector2(-176,0)
@export var main_music = "challenge"
@export var player_blind = false

@onready var player = $player
@onready var camera_2d = $Camera2D
@onready var camera_limits = $camera_limits
@onready var ui = $ui
@onready var pause_menu = $ui/pause_menu

var end_scene = "res://menus/challenge_finish_menu.tscn"
var pausable = true
var run_start = false
var level_id_board
var mode_string = ""

func _input(event):
	if event.is_action_pressed("pause"):
		if pausable:
			pause_menu.pause()
		pausable = !pausable
	if event is InputEventMouseMotion:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _ready():
	$player/blind_obscure.visible = player_blind
	sounds.load_starting_music([main_music],1,-80)
	sounds.fade_in_music(main_music,1,-10)
	set_up_mode()
	set_up_steam()
	set_up_timer()
	set_up_run()
	set_camera_limits()
	get_tree().paused = false 
	ui.enter_transition()
	SaveAndLoad.update_save_data()

func _process(delta):
	fix_camera_smoothing()
	if (Input.is_action_pressed("reset_level") and Input.is_action_pressed("reset_control")) || Input.is_action_pressed("controller_reset_level"):
		change_scene()

func set_up_mode():
	level_id_board = level_id
	if stats["save_data"]["hard_mode"]:
		mode_string+="_hard"
		$checkpoints.hide()
	else:
		mode_string+="_normal"
		$checkpoints.show()
	level_id_board+=mode_string

func set_up_steam():
	steam.level_id_board = level_id_board
	Steam.findLeaderboard(level_id_board)

func set_up_timer():
	global_timer.time = 0
	global_timer.timer_on = false

func set_up_run():
	camera_2d.position_smoothing_enabled = false
	camera_2d.global_position = player.global_position

func set_camera_limits():
	camera_limits.hide()
	camera_2d.limit_left = camera_limits.global_position.x
	camera_2d.limit_right = camera_limits.global_position.x+camera_limits.size.x
	camera_2d.limit_top = camera_limits.global_position.y
	camera_2d.limit_bottom = camera_limits.global_position.y+camera_limits.size.y

func _on_start_zone_start_timer():
	run_start = true
	@warning_ignore("narrowing_conversion")
	sounds.play_sfx("bark_twice",randf_range(0.9,1.2), -25)
	start_timer()

func start_timer():
	global_timer.timer_on = true

var fixed_camera_smoothing = false
func fix_camera_smoothing():
	if !fixed_camera_smoothing:
		fixed_camera_smoothing = true
		camera_2d.position_smoothing_enabled = true

func change_scene(new_scene = null):
	ui.exit_transition()
	get_tree().paused = true
	await get_tree().create_timer(stats.transition_time).timeout
	if new_scene:
		get_tree().call_deferred("change_scene_to_file",new_scene)
	else:
		get_tree().call_deferred("reload_current_scene")

func _on_player_respawn():
	ui.exit_transition()
	get_tree().paused = true
	await get_tree().create_timer(stats.transition_time).timeout
	player.velocity = Vector2.ZERO
	player.position = spawn_point
	player.invincible = false
	camera_2d.position_smoothing_enabled = false
	camera_2d.position = spawn_point
	get_tree().paused = false
	await get_tree().create_timer(.1).timeout
	ui.enter_transition()
	camera_2d.position_smoothing_enabled = true

func _on_checkpoint_activate_checkpoint(respawn_position,checkpoint):
	if !stats["save_data"]["hard_mode"]:
		for point in $checkpoints.get_children():
			point.active = false
			point.animation_player.play("RESET")
		checkpoint.active = true
		spawn_point = respawn_position

func _on_player_leaderboard():
	$ui/leaderboard.show()

func _on_player_close_interactables():
	$ui/leaderboard.hide()
	$ui/stats.hide()

func _on_challenge_finish_body_entered(body):
	global_timer.timer_on = false
	update_stats()
	var new_best = await update_score()
	player.paused()
	player.hide()
	get_tree().call_deferred("change_scene_to_file",end_scene)

func update_stats():
	stats["save_data"]["challenge_data"][level_id][mode_string+"_reunions"] += 1

func update_score():
	if run_start != true || GlobalTimer.time<2:
		return false
	else:
		var new_best = false
		if global_timer.time < stats["save_data"]["challenge_data"][level_id][mode_string+"_time"]:
			stats["save_data"]["challenge_data"][level_id][mode_string+"_time"] = global_timer.time
			new_best = true
		var modified_time = global_timer.time*1000
		Steam.uploadLeaderboardScore(modified_time)
		SaveAndLoad.update_save_data()
		return new_best

func _on_toilet_unlock_toilet():
	stats["save_data"]["items"]["toilet"] = true
	sounds.play_sfx("pickup", randf_range(0.6,1.4), -10)
	ui.pop_up("Toilet Unlocked")
	SaveAndLoad.update_save_data()

extends TextureRect

var stats = Stats
var sounds = Sounds

@onready var exit_button = $exit_button
@onready var transition = $transition

var first_time = false

func _ready():
	get_tree().paused = false
	sounds.play_music("dog_days")

func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):
		_on_exit_button_pressed()

func mode_select():
	transition.fade_out_credits()
	await get_tree().create_timer(1).timeout
	if first_time:
		get_tree().change_scene_to_file("res://menus/mode_select.tscn")
	else:
		get_tree().change_scene_to_file("res://menus/main_menu.tscn")

func _on_exit_button_pressed():
	@warning_ignore("narrowing_conversion")
	Sounds.play_sfx("click",randf_range(.8,1.2),-10)
	transition.fade_out()
	await get_tree().create_timer(stats.transition_time).timeout
	get_tree().change_scene_to_file("res://menus/main_menu.tscn")

func _on_bone_collector_area_entered(area):
	@warning_ignore("narrowing_conversion")
	sounds.play_sfx("pickup", randf_range(0.6,1.4), -10)	
	area.queue_free()
extends Area2D

var stats = Stats

@onready var animated_sprite_2d = $AnimatedSprite2D
@onready var chat_icon = $chat_icon
@onready var sleep_zs = $sleep_zs

var interactable = false
var interacting = false
var states = [
	"sleep",
	"wake_up",
	"idle_forward",
]
var state = "sleep"
var progression = 0

signal talk(_progression)
signal end_speech
@warning_ignore("unused_signal")
signal set_up_mage

func _input(event):
	if (event.is_action_pressed("action") && interactable or event.is_action_pressed("controller_action")) && interactable:
		talk.emit(progression)
		state_progress()

func _ready():
	check_progression()
	progression = stats["save_data"]["mage_progression"]
	#set_up_mage.emit()

#check if need to advance
func check_progression():
	match stats["save_data"]["mage_progression_next"]:
		0:
			sleep_zs.show()
		1:
			stats["save_data"]["mage_progression"] = 1
		2:
			if stats["save_data"]["challenge_data"]["challenge_4"]["_normal_reunions"] > 0:
				stats["save_data"]["mage_progression"] = 2
		3:
			if stats.calc_total_reunions() > 0:
				stats["save_data"]["mage_progression"] = 3
		4:
			stats["save_data"]["mage_progression"] = 4
		5:
			if stats["save_data"]["phoenix_dlc"]:
				stats["save_data"]["mage_progression"] = 5
		6:
			if stats.calc_total_dlc_reunions() > 0:
				stats["save_data"]["mage_progression"] = 6
		7:
			pass

#when you talk
func state_progress():
	match progression:
		0:
			if state == "sleep":
				state = "wake_up"
				wake_up()
				sleep_zs.hide()
				stats["save_data"]["mage_progression_next"] = 1
		1:
			if stats["save_data"]["mage_progression_next"] == 1:
				stats["save_data"]["mage_progression_next"] = 2
		2:
			if stats["save_data"]["mage_progression_next"] == 2:
				stats["save_data"]["mage_progression_next"] = 3
		3:
			if stats["save_data"]["mage_progression_next"] == 3:
				stats["save_data"]["mage_progression_next"] = 4
		4:
			if stats["save_data"]["mage_progression_next"] == 4:
				stats["save_data"]["mage_progression_next"] = 5
		5:
			if stats["save_data"]["mage_progression_next"] == 5:
				stats["save_data"]["mage_progression_next"] = 6
		6:
			if stats["save_data"]["mage_progression_next"] == 6:
				stats["save_data"]["mage_progression_next"] = 7
		7:
			pass

func wake_up():
	animated_sprite_2d.play("wake_up")
	await animated_sprite_2d.animation_finished
	animated_sprite_2d.play("idle_side")

@warning_ignore("unused_parameter")
func _on_body_entered(body):
	interactable = true
	chat_icon.show()

@warning_ignore("unused_parameter")
func _on_body_exited(body):
	interactable = false
	chat_icon.hide()
	end_speech.emit()

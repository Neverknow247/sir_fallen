extends Interactable_script

@onready var board_label = $board_label

func _ready():
	if stats.calc_total_reunions() > 0:
		unlocked = true
		board_label.text = "Leaderboards"


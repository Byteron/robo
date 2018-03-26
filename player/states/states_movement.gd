extends Node

enum STATE_ID {IDLE, WALK, DASH, JUMP, CLIMB, FALL, WALL}

var current = null
var previous = null

func change(state):
	if state != current:
		previous = current
		current = state

func get_current_string():
	match current:
		IDLE: return "Idle"
		WALK: return "Walk"
		FALL: return "Fall"
		WALL: return "Wall"
		JUMP: return "Jump"
		CLIMB: return "Climb"
		DASH: return "Dash"
	return "None"

func get_previous_string():
	match previous:
		IDLE: return "Idle"
		WALK: return "Walk"
		FALL: return "Fall"
		WALL: return "Wall"
		JUMP: return "Jump"
		CLIMB: return "Climb"
		DASH: return "Dash"
	return "None"
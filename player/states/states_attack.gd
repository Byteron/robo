extends Node

enum STATE_ID {READY, ATTACK}

var current = null
var previous = null

func change(state):
	if state != current:
		previous = current
		current = state
	
func get_current_string():
	match current:
		READY: return "Ready"
		ATTACK: return "Attack"
	return "None"

func get_previous_string():
	match previous:
		READY: return "Ready"
		ATTACK: return "Attack"
	return "None"
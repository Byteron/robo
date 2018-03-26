extends Node2D

export var value = 10

func _ready():
	$Area2D.connect("body_entered", self, "_collect_gem")


func _collect_gem(body):
	var player = get_owner().get_node("Player")
	player.ENERGY_MAX += value
	queue_free()
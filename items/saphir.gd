extends Node2D

export var value = 5

func _ready():
	$Area2D.connect("body_entered", self, "_collect_gem")


func _collect_gem(body):
	var player = get_owner().get_node("Player")
	player.JUMPFORCE += value
	queue_free()
extends Node2D

var MrPalo = preload("res://MrPalo.tscn")

var Player1
var Player2
var Player1_on_left

func _ready():
	Player1 = MrPalo.instance()
	Player1.player = 1
	add_child(Player1)
	Player2 = MrPalo.instance()
	Player2.player = 2
	add_child(Player2)


func _process(delta):
	if Player1.position.x < Player2.position.x:
		Player1_on_left = true
		Player1.must_face_right = true
		Player2.must_face_right = false
	else:
		Player1_on_left = false
		Player1.must_face_right = false
		Player2.must_face_right = true

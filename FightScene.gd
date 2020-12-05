extends Node2D

export (PackedScene) var MrPalo

var Player1
var Player2
var player1_on_left = true

func _ready():
	Player1 = MrPalo.instance()
	Player1.player = 1
	add_child(Player1)
	Player2 = MrPalo.instance()
	Player2.player = 2
	Player2.waiting_for_flip = true
	add_child(Player2)

func flip_players(delta):
	var flip_ordered = false
	if player1_on_left == false and flip_ordered == false:
		flip_ordered = true
		Player1.waiting_for_flip = true
		Player2.waiting_for_flip = true
	if player1_on_left == true and flip_ordered == false:
		flip_ordered = true
		Player1.waiting_for_flip = true
		Player2.waiting_for_flip = true
		
	
func _process(delta):
	if Player1.position.x < Player2.position.x:
		player1_on_left = true
	else: 
		player1_on_left = false
	
	flip_players(delta)

extends Node2D

var MrPalo = preload("res://fighters/MrPalo.tscn")
var Training_stage = preload("res://stages//TrainingStage.tscn")

var player1
var player2
var stage
var player1_on_left
var stage_size

func _ready():
	stage = Training_stage.instance()
	stage.name = "Stage"
	add_child(stage)
	stage_size = $Stage.get_node("Background").get_rect()
	player1 = MrPalo.instance()
	player1.player = 1
	player1.name = "Player1"
	add_child(player1)
	player2 = MrPalo.instance()
	player2.player = 2
	player2.name = "Player2"
	add_child(player2)
	player1.stage_size = stage_size
	player2.stage_size = stage_size
	$Camera2D.stage_size = stage_size
	player1.find_nodes()
	player2.find_nodes()
	$Camera2D.find_nodes()

func _process(delta):
	if player1.position.x < player2.position.x:
		player1_on_left = true
		player1.must_face_right = true
		player2.must_face_right = false
	else:
		player1_on_left = false
		player1.must_face_right = false
		player2.must_face_right = true
	update()
	
func _draw():
	draw_rect(player1.hit_area_rect, Color(1, 0, 1))
	draw_rect(player2.hurt_area_rect, Color(0, 1, 1))
	draw_rect(player2.hitfx_area_rect, Color(1, 1, 0))

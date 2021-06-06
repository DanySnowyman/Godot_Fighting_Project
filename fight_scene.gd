extends Node2D

var MrPalo = preload("res://fighters/mr_palo/mr_palo.tscn")
var RedPalo = preload("res://fighters/red_palo/red_palo.tscn")
var Training_stage = preload("res://stages/training_stage/training_stage.tscn")
var Hits_FX = preload("res://hits_fx.tscn")

var player1
var player2
var stage
var hud
var hitsfx
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
	player2 = RedPalo.instance()
	player2.player = 2
	player2.name = "Player2"
	add_child(player2)
	player1.stage_size = stage_size
	player2.stage_size = stage_size
	$Camera2D.stage_size = stage_size
	player1.find_nodes()
	player2.find_nodes()
	$Camera2D.find_nodes()
	$Camera2D.center_camera()
	yield($Transition.fade_out(1), "completed")
	player1.can_control = true
	player2.can_control = true
	
func set_new_round():
	yield($Transition.fade_in(1), "completed")
	get_tree().reload_current_scene()
	
func _process(delta):
	if is_instance_valid(player1):
		if player1.position.x < player2.position.x:
			player1_on_left = true
			player1.must_face_right = true
			player2.must_face_right = false
		else:
			player1_on_left = false
			player1.must_face_right = false
			player2.must_face_right = true
	else: pass
	update()
	
#func _draw():
#	draw_rect(player1.hit_area_rect, Color(1, 0, 1))
#	draw_rect(player2.hurt_area_rect, Color(0, 1, 1))
#	draw_rect(player2.hitfx_area_rect, Color(1, 1, 0))

func play_hitfx(facing_right, hitfx_area_rect, hit_type, hit_strenght):
	hitsfx = Hits_FX.instance()
	hitsfx.position.x = rand_range(hitfx_area_rect.position.x,\
					hitfx_area_rect.position.x + hitfx_area_rect.size.x)
	hitsfx.position.y = rand_range(hitfx_area_rect.position.y,\
					hitfx_area_rect.position.y + hitfx_area_rect.size.y)
	add_child(hitsfx)
	hitsfx.call_animation(facing_right, hit_type)

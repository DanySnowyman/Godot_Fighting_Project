extends Camera2D

var player1
var player2
var stage_size := Rect2()
var screen_size := Rect2()

func _ready():
	screen_size = get_viewport_rect()

func find_nodes():
	player1 = get_parent().get_node("Player1")
	player2 = get_parent().get_node("Player2")
	
func center_camera():
	position.x = stage_size.end.x / 2
	position.y = 500

func _process(delta):
	if is_instance_valid(player1):
		if player1.is_stuck == false or player2.is_stuck == false:
			position.x = (player1.position.x + player2.position.x) / 2
			position.y = ((player1.position.y - 56) + (player2.position.y - 56)) / 2
			limit_left = stage_size.position.x
			limit_right = stage_size.end.x
			limit_top = stage_size.position.y
			limit_bottom = stage_size.end.y
			position.x = clamp(position.x, stage_size.position.x + screen_size.end.x / 2, 
							stage_size.end.x - screen_size.end.x / 2)
		else: pass
	else: pass

extends "res://fighters/base_character.gd"

func _ready():
	cpu_level = 2
	
func forward_grab(): # Lanzamiento
	var rival_sprite = rival.get_node("Sprite")
	yield(get_tree().create_timer(0.3, false), "timeout")
	if state == is_.GRABBING:
		$AnimationPlayer.stop(true)
		if facing_right == true:
			self.position.x += 20
		else: self.position.x -= 20
		self.z_index = 1
		$Sprite.frame = 360
		rival_sprite.flip_h = true
		if facing_right == true:
			rival.position = self.position + Vector2(-35, -15)
		else: rival.position = self.position + Vector2(35, -15)
		rival_sprite.frame = 93
		yield(get_tree().create_timer(0.25, false), "timeout")
		$Sprite.frame = 361
		if facing_right == true:
			rival.position = self.position + Vector2(-5, -35)
		else: rival.position = self.position + Vector2(5, -35)
		rival_sprite.rotation_degrees = 270
		yield(get_tree().create_timer(0.10, false), "timeout")
		$Sprite.frame = 362
		if facing_right == true:
			rival.position = self.position + Vector2(30, -50)
		else: rival.position = self.position + Vector2(-30, -50)
		rival_sprite.rotation_degrees = 180
		rival.throwed(-100, 10)
		yield(get_tree().create_timer(0.15, false), "timeout")
		$Sprite.frame = 363
		rival_sprite.frame = 107
		rival_sprite.rotation_degrees = 0
		yield(get_tree().create_timer(0.40, false), "timeout")
		stand()
	else: pass

func backward_grab(): # Suplex!
	var rival_sprite = rival.get_node("Sprite")
	yield(get_tree().create_timer(0.3, false), "timeout")
	if state == is_.GRABBING:
		$AnimationPlayer.stop(true)
		tween.remove_all()
		self.z_index = 1
		$Sprite.frame = 368
		if facing_right == true:
			rival.position = self.position + Vector2(25, -10)
		if facing_right == false:
			rival.position = self.position + Vector2(-25, -10)
		rival_sprite.frame = 93
		rival_sprite.flip_h = true
		yield(get_tree().create_timer(0.2, false), "timeout")
		$Sprite.frame = 369
		if facing_right == true:
			rival.position = self.position + Vector2(-10, -40)
		if facing_right == false:
			rival.position = self.position + Vector2(10, -40)
		rival_sprite.rotation_degrees = 90
		yield(get_tree().create_timer(0.3, false), "timeout")
		$Sprite.frame = 370
		if facing_right == true:
			rival.position = self.position + Vector2(-60, 35)
		if facing_right == false:
			rival.position = self.position + Vector2(60, 35)
		rival_sprite.frame = 95
		rival_sprite.rotation_degrees = 180
		yield(get_tree().create_timer(0.2, false), "timeout")
		$Sprite.frame = 370
		rival_sprite.frame = 107
		rival_sprite.rotation_degrees = 0
		rival.throwed(80, 40)
		$Sprite.frame = 371
		yield(get_tree().create_timer(0.2, false), "timeout")
		$Sprite.frame = 372
		yield(get_tree().create_timer(0.2, false), "timeout")
		stand()
	else: pass

extends "res://fighters/base_character.gd"

func _ready():
	$Sprite.modulate = Color(1, 0.494118, 0.494118)
	cpu_level = 5

func forward_grab(): # Palizón
	var rival_sprite = rival.get_node("Sprite")
	yield(get_tree().create_timer(0.3, false), "timeout")
	if state == is_.GRABBING:
		rival.grab_offset = Vector2(40, 0)
		rival.position_is_locked = true
		$AnimationPlayer.playback_speed = 1.5
		strike_data(10, 10, 0, "Heavy", "Mid", "Normal", 0, false)
		$AnimationPlayer.play("Attack standing LP")
		for i in range (5):
			$AnimationPlayer.queue("Attack crouching LP")
			$AnimationPlayer.queue("Attack standing LK")
		$AnimationPlayer.queue("Attack standing MP")
		$AnimationPlayer.queue("Attack crouching MK")
		$AnimationPlayer.queue("Attack standing MK")
		$AnimationPlayer.queue("Attack crouching MP")
		$AnimationPlayer.queue("Attack standing HK")
		$AnimationPlayer.queue("Attack crouching HP")
		$AnimationPlayer.playback_speed = 1
		yield(get_tree().create_timer(4.3, false), "timeout")
		rival.position_is_locked = false
		rival.grab_offset = Vector2(0, 0)
		rival.air_received_hit(true)
		yield(get_tree().create_timer(1, false), "timeout")
		stand()
	else: pass
	
func backward_grab(): # Zangief SPD
	var rival_sprite = rival.get_node("Sprite")
	yield(get_tree().create_timer(0.3, false), "timeout")
	if state == is_.GRABBING:
		$AnimationPlayer.stop(true)
		tween.remove_all()
		if facing_right == true:
			self.position.x += 20
		else: self.position.x -= 20
		self.z_index = 1
		$Sprite.frame = 376
		if facing_right == true:
			rival.position = self.position + Vector2(40, 0)
		else: rival.position = self.position + Vector2(-40, 0)
		rival_sprite.frame = 94
		yield(get_tree().create_timer(0.25, false), "timeout")
		$Sprite.frame = 377
		rival_sprite.frame = 95
		rival_sprite.rotation_degrees = 90
		if facing_right == true:
			rival.position = self.position + Vector2(20, 10)
		else: rival.position = self.position + Vector2(-20, 10)
		yield(get_tree().create_timer(0.15, false), "timeout")
		$Sprite.frame = 378
		rival_sprite.frame = 92
		rival_sprite.rotation_degrees = 180
		if facing_right == true:
			rival.position = self.position + Vector2(15, -10)
		else: rival.position = self.position + Vector2(-15, -10)
		rival.grab_offset = Vector2(0, 0)
		rival.position_is_locked = true
		yield(get_tree().create_timer(0.10, false), "timeout")
		tween_parable(100, 100, 1.0)
		for i in range(8):
			if tween.is_active() == true:
				self.z_index = 1
				$Sprite.frame = 379
				rival_sprite.frame = 93
				rival_sprite.flip_h = false
				rival_sprite.position = to_local(rival.position) + Vector2(-8, -55)
				yield(get_tree().create_timer(0.1, false), "timeout")
			else: break
			if tween.is_active() == true:
				$Sprite.frame = 380
				rival_sprite.frame = 73
				rival_sprite.position = to_local(rival.position) + Vector2(-8, -55)
				yield(get_tree().create_timer(0.1, false), "timeout")
			else: break
			if tween.is_active() == true:
				$Sprite.frame = 379
				$Sprite.flip_h = true
				rival_sprite.frame = 93
				rival_sprite.flip_h = true
				rival_sprite.position = to_local(rival.position) + Vector2(8, -55)
				yield(get_tree().create_timer(0.1, false), "timeout")
			else: break
			if tween.is_active() == true:
				self.z_index = -1
				$Sprite.frame = 380
				$Sprite.flip_h = false
				rival_sprite.frame = 73
				rival_sprite.position = to_local(rival.position) + Vector2(8, -55)
				yield(get_tree().create_timer(0.1, false), "timeout")
			else: break
		rival.position_is_locked = false
		$Sprite.frame = 381
		rival_sprite.position = rival.initial_sprite_pos
		rival_sprite.frame = 95
		rival_sprite.flip_h = false
		rival_sprite.rotation_degrees = 180
		if facing_right == true:
			rival.position = self.position + Vector2(20, 30)
		else: rival.position = self.position + Vector2(-20, 30)
		yield(get_tree().create_timer(0.5, false), "timeout")
		rival_sprite.frame = 107
		rival_sprite.rotation_degrees = 0
		rival_sprite.flip_h = true
		rival.throwed(-80, 50)
		tween_parable(-50, 20, 0.5)
		$Sprite.frame = 49
		yield(get_tree().create_timer(0.5, false), "timeout")
		stand()
	else: pass

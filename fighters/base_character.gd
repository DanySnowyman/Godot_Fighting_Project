extends Area2D

var player
var px
var cpu_level = 0 # CERO es PLAYER
var rival
var damaging_area

var Fireball = preload("res://fighters/base_projectile.tscn")

enum is_ {LOCKED, STANDING, CROUCHING, DASHING, PRE_JUMP, JUMPING, ATTACKING_ST, ATTACKING_CR,
		ATTACKING_SP, AIR_ATTACKING, AIR_ATTACKING_SP, GRABBING, GRABBED, BLOCKING_H, BLOCKING_L,
		BLOCK_STUNNED_H, BLOCK_STUNNED_L, HIT_STUNNED_ST, HIT_STUNNED_CR, AIR_STUNNED, FALLING,
		GROUND_IMPACT, KNOCKED_DOWN, WAKING_UP}

enum do_ {STAND, CROUCH, WALK_F, WALK_B, DASH_F, DASH_B, JUMP_V, JUMP_F, JUMP_B}

var state
var cpu_move
var can_control = false
var facing_right = true
var must_face_right
var waiting_for_flip = false
var is_stuck
var position_is_locked = false
var is_walking_forward = false
var is_walking_backward = false
var is_dashing_forward = false
var is_dashing_backward = false
var is_jumping_forward = false
var is_jumping_backward = false
var is_shaked = false
var knockdown_level = 0 # CERO es "NADA", UNO es "SOFT", DOS es "HARD"
var nearly_grabbed = false
var grab_offset = Vector2()
var players_collide = false
var proxboxes_detected = 0
var can_guard = false
var changed_guard = false
var just_hitted = false
var already_crouched = false
var dash_r_ready = false
var dash_l_ready = false
var can_special_cancel = false
var can_auto_cancel = false
var can_normal_cancel = false
var can_dash_cancel = false
var startup_frames = false
var initial_sprite_pos = Vector2()
var last_position = Vector2()
var hitted_area
var health_level
var power_level = 0
var power_sp_inc = 20
var combo_counter = 0
var debug_mode = true

var sp1_input_count = 0
var sp2_input_count = 0
var sp3_left_charge = 0
var sp3_right_charge = 0
var sp4_slap_buffer = 0

var hit_damg # Daño producido
var hit_stun # Aturdimiento producido
var hit_push # Cantidad de empuje hacia atrás del rival
var hit_strg # Light, Medium, Heavy, Launch, Sweep
var hit_area # High, Low or Mid (Si debe bloquearse alto, bajo o ambos valen)
var hit_type # Normal < Special < Powered < Ultimate
var hit_canc # 0 = no cancelable, 1 = special cancel, 2 = special + auto, 3 = special + normal
var hit_jugg # Si el golpe permite golpear al rival abatido en el aire

var hit_area_pos:= Vector2()
var hit_area_size:= Vector2()
var hurt_area_pos:= Vector2()
var hurt_area_size:= Vector2()
var hit_area_rect:= Rect2() # Eliminar tras video
var hurt_area_rect:= Rect2() # Eliminar tras video
var hitfx_area_rect:= Rect2()

export var char_name : String
export var init_health = 1000
export var init_stun = 1000
export var walk_forward_speed = 200
export var walk_backward_speed = 150
export var jump_height = 80
export var jump_f_lenght = 120
export var jump_b_lenght = 100
export var jump_asc_time = 0.4
export var jump_des_time = 0.4
export var dash_f_dist = 80
export var dash_b_dist = 60
export var dash_f_time = 0.4
export var dash_b_time = 0.4
export var rolling_back_dist = 60

var motion := Vector2()
var camera
var hud
var camera_pos := Vector2()
var stage_size := Rect2()

var airborne_hit_lenght = 100
var ground_impact_lenght = 20

const FREEZE_HEAVY = 0.15
const FREEZE_MEDIUM = 0.13
const FREEZE_LIGHT = 0.11

onready var tween = get_node("Tween")
onready var pushray = get_node("PushingRay")
onready var fireballs

func _ready():
	if player == 1:
		px = "P1"
		$HUD/State.set_global_position(Vector2(20, 40))
		$HUD/State.align = HALIGN_LEFT
		self.set_collision_layer(1)
		self.set_collision_mask(9216)
		$HitBoxes.set_collision_layer(4)
		$HurtBoxes.set_collision_layer(2)
		$HurtBoxes.set_collision_mask(4096 + 32768)
		$ProximityBox.set_collision_layer(8)
		$GrabBox.set_collision_layer(16)
		$GrabBox.set_collision_mask(1024)
		$PushingRay.set_collision_mask(1024)
		add_to_group("Player_1")
		
	else:
		px = "P2"
		$HUD/State.set_global_position(Vector2(364, 40))
		$HUD/State.align = HALIGN_RIGHT
		$HUD/State.grow_horizontal = 0
		self.set_collision_layer(1024)
		self.set_collision_mask(9)
		$HitBoxes.set_collision_layer(4096)
		$HurtBoxes.set_collision_layer(2048)
		$HurtBoxes.set_collision_mask(36)
		$ProximityBox.set_collision_layer(8192)
		$GrabBox.set_collision_layer(16384)
		$GrabBox.set_collision_mask(1)
		$PushingRay.set_collision_mask(1)
		add_to_group("Player_2")
	
	state = is_.STANDING
	initial_sprite_pos = $Sprite.position
	$AnimationPlayer.play("Stand")
	$ProximityBox/ProxBox1.disabled = true
	$HitBoxes/HitBox1.disabled = true
	health_level = init_health

func find_nodes():
	if player == 1:
		rival = get_parent().get_node("Player2")
		self.position = Vector2((stage_size.end.x / 2) - 80, (stage_size.end.y - 20))
	else:
		rival = get_parent().get_node("Player1")
		self.position = Vector2((stage_size.end.x / 2) + 80, (stage_size.end.y - 20))
	camera = get_parent().get_node("Camera2D")
	hud = get_parent().get_node("HUD")
	hud.initialize_health(player, health_level)

func change_facing_direction():
	if facing_right != must_face_right:
		waiting_for_flip = true

func facing_direction():
	if waiting_for_flip == true and (state == is_.STANDING or state == is_.CROUCHING):
		waiting_for_flip = false
		facing_right = not facing_right
		walk_forward_speed = -walk_forward_speed
		walk_backward_speed = -walk_backward_speed
		jump_f_lenght = -jump_f_lenght
		jump_b_lenght = -jump_b_lenght
		dash_f_dist = -dash_f_dist
		dash_b_dist = -dash_b_dist
		airborne_hit_lenght = -airborne_hit_lenght
		rolling_back_dist = -rolling_back_dist
		ground_impact_lenght = -ground_impact_lenght
		self.scale.x *= -1

func player_control(delta):
	# Negate opposite directions ------------------------------------------
	if state == is_.STANDING:
		if Input.is_action_pressed("%s_LEFT" % px) and Input.is_action_pressed("%s_RIGHT" % px):
			stand()
		else:
	# Walk right & standing block --------------------------------------------
			if Input.is_action_pressed("%s_RIGHT" % px):
				if facing_right == true:
					walk_forward(delta)
				else:
					if can_guard == true:
						block_standing()
					else: walk_backward(delta)
			if Input.is_action_just_released("%s_RIGHT" % px):
				stand()
	# Walk left & standing block -------------------------------------------
			if Input.is_action_pressed("%s_LEFT" % px):
				if facing_right == false:
					walk_forward(delta)
				else:
					if can_guard == false:
						walk_backward(delta)
					else: block_standing()
			if Input.is_action_just_released("%s_LEFT" % px):
				stand()
	# Crouching block --------------------------------------------------------
	if state == is_.STANDING or state == is_.CROUCHING:
		if Input.is_action_pressed("%s_LEFT" % px) and Input.is_action_pressed("%s_DOWN" % px):
			if can_guard == true and facing_right == true:
				block_crouching()
		if Input.is_action_pressed("%s_RIGHT" % px) and Input.is_action_pressed("%s_DOWN" % px):
			if can_guard == true and facing_right == false:
				block_crouching()
			else: crouch()
	# Exit from blocking -----------------------------------------------------
	if state == is_.BLOCKING_H:
		if facing_right == true:
			if Input.is_action_just_released("%s_LEFT" % px) or can_guard == false:
				state = is_.STANDING
			elif Input.is_action_just_pressed("%s_DOWN" % px):
				$Sprite.frame = 85
				state = is_.BLOCKING_L
		else:
			if Input.is_action_just_released("%s_RIGHT" % px) or can_guard == false:
				state = is_.STANDING
			elif Input.is_action_just_pressed("%s_DOWN" % px):
				$Sprite.frame = 85
				state = is_.BLOCKING_L
	if state == is_.BLOCKING_L:
		if facing_right == true:
			if Input.is_action_pressed("%s_LEFT" % px) and \
						Input.is_action_just_released("%s_DOWN" % px):
					$Sprite.frame = 81
					state = is_.BLOCKING_H
			elif Input.is_action_just_released("%s_DOWN" % px):
				stand()
			if Input.is_action_just_released("%s_LEFT" % px) or can_guard == false:
				$Sprite.frame = 65
				state = is_.CROUCHING
		else:
			if Input.is_action_pressed("%s_RIGHT" % px) and \
						Input.is_action_just_released("%s_DOWN" % px):
					$Sprite.frame = 81
					state = is_.BLOCKING_H
			elif Input.is_action_just_released("%s_DOWN" % px):
				stand()
			if Input.is_action_just_released("%s_RIGHT" % px) or can_guard == false:
				$Sprite.frame = 65
				state = is_.CROUCHING
	# Crouch ------------------------------------------------------------------
	if state == is_.STANDING:
		if Input.is_action_pressed("%s_DOWN" % px):
			crouch()
	if state == is_.CROUCHING:
		if Input.is_action_pressed("%s_DOWN" % px) == false:
			stand()
		else: crouch()
	# Alternate blocking ------------------------------------------------------
	if state == is_.BLOCK_STUNNED_H:
		if changed_guard == false:
			if facing_right == true:
				if Input.is_action_pressed("%s_DOWN" % px) and \
						Input.is_action_pressed("%s_LEFT" % px):
					if $AnimationPlayer.current_animation_position > 0.15:
						changed_guard = true
						$AnimationPlayer.stop()
						$Sprite.frame = 85
						already_crouched = true
						state = is_.BLOCK_STUNNED_L
			else:
				if Input.is_action_pressed("%s_DOWN" % px) and \
						Input.is_action_pressed("%s_RIGHT" % px):
					if $AnimationPlayer.current_animation_position > 0.15:
						changed_guard = true
						$AnimationPlayer.stop()
						$Sprite.frame = 85
						already_crouched = true
						state = is_.BLOCK_STUNNED_L
	if state == is_.BLOCK_STUNNED_L:
		if changed_guard == false:
			if Input.is_action_pressed("%s_DOWN" % px) == false:
				if $AnimationPlayer.current_animation_position > 0.15:
					changed_guard = true
					$AnimationPlayer.stop()
					$Sprite.frame = 81
					already_crouched = false
					state = is_.BLOCK_STUNNED_H
	# Jump --------------------------------------------------------------------
	if state == is_.STANDING or state == is_.BLOCKING_H:
		if Input.is_action_pressed("%s_UP" % px):
			state = is_.PRE_JUMP
			$AnimationPlayer.play("Pre jump")
			$TweenTimer.start($AnimationPlayer.current_animation_length)
			yield($TweenTimer, "timeout")
			if state == is_.PRE_JUMP or state == is_.AIR_ATTACKING:
				if Input.is_action_pressed("%s_RIGHT" % px):
					if facing_right == true:
						jump_forward()
					else: jump_backward()
				elif Input.is_action_pressed("%s_LEFT" % px):
					if facing_right == true:
						jump_backward()
					else: jump_forward()
				else:
					jump_vertical()
	# Dash forward -----------------------------------------------------------
	if Input.is_action_just_pressed("%s_RIGHT" % px) and dash_r_ready == false:
		dash_r_ready = true
		dash_l_ready = false
		yield(get_tree().create_timer(0.2, false), "timeout")
		dash_r_ready = false
	if state == is_.STANDING or state == is_.BLOCKING_H:
		if Input.is_action_just_pressed("%s_RIGHT" % px) and dash_r_ready == true:
			if facing_right == true:
				dash_forward()
			else: dash_backward()
	# Dash backward -----------------------------------------------------------
	if Input.is_action_just_pressed("%s_LEFT" % px) and dash_l_ready == false:
		dash_l_ready = true
		dash_r_ready = false
		yield(get_tree().create_timer(0.2, false), "timeout")
		dash_l_ready = false
	if state == is_.STANDING or state == is_.BLOCKING_H:
		if Input.is_action_just_pressed("%s_LEFT" % px) and dash_l_ready == true:
			if facing_right == true:
				dash_backward()
			else: dash_forward()
	# Grabbing ------------------------------------------------------------------
	if Input.is_action_just_pressed("%s_LP" % px) and Input.is_action_just_pressed("%s_LK" % px):
		if state == is_.STANDING or state == is_.BLOCKING_H:
			grab_attempt()
		elif state == is_.JUMPING:
			air_grab_attempt()
	# Counter grab --------------------------------------------------------------
	if nearly_grabbed == true and state != is_.AIR_ATTACKING:
		if Input.is_action_just_pressed("%s_LP" % px) and \
				Input.is_action_just_pressed("%s_LK" % px):
			grab_escape()
	# Overhead --------------------------------------------------------------------------------
	if state == is_.STANDING or state == is_.CROUCHING \
			or state == is_.BLOCKING_H or state == is_.BLOCKING_L:
		if Input.is_action_just_pressed("%s_MP" % px) and \
				Input.is_action_just_pressed("%s_MK" % px):
			overhead()
	# Standing normals ----------------------------------------------------------
	if state == is_.STANDING or state == is_.BLOCKING_H:
		if Input.is_action_just_pressed("%s_LP" % px) and \
				Input.is_action_just_pressed("%s_LK" % px) == false:
			standing_normal("LP")
		if Input.is_action_just_pressed("%s_MP" % px) and \
				Input.is_action_just_pressed("%s_MK" % px) == false:
			standing_normal("MP")
		if Input.is_action_just_pressed("%s_HP" % px):
			standing_normal("HP")
		if Input.is_action_just_pressed("%s_LK" % px) and \
				Input.is_action_just_pressed("%s_LP" % px) == false:
			standing_normal("LK")
		if Input.is_action_just_pressed("%s_MK" % px) and \
				Input.is_action_just_pressed("%s_MP" % px) == false:
			standing_normal("MK")
		if Input.is_action_just_pressed("%s_HK" % px):
			standing_normal("HK")
	# Crouching normals -------------------------------------------------------
	if state == is_.CROUCHING or state == is_.BLOCKING_L:
		if Input.is_action_just_pressed("%s_LP" % px) and \
				Input.is_action_just_pressed("%s_LK" % px) == false:
			crouching_normal("LP")
		if Input.is_action_just_pressed("%s_MP" % px) and \
				Input.is_action_just_pressed("%s_MK" % px) == false:
			crouching_normal("MP")
		if Input.is_action_just_pressed("%s_HP" % px):
			crouching_normal("HP")
		if Input.is_action_just_pressed("%s_LK" % px) and \
				Input.is_action_just_pressed("%s_LP" % px) == false:
			crouching_normal("LK")
		if Input.is_action_just_pressed("%s_MK" % px) and \
				Input.is_action_just_pressed("%s_MP" % px) == false:
			crouching_normal("MK")
		if Input.is_action_just_pressed("%s_HK" % px):
			crouching_normal("HK")
	# Air normals -------------------------------------------------------------
	if state == is_.JUMPING or state == is_.PRE_JUMP:
		if Input.is_action_just_pressed("%s_LP" % px) and \
				Input.is_action_just_pressed("%s_LK" % px) == false:
			air_normal("LP")
		if Input.is_action_just_pressed("%s_MP" % px):
			air_normal("MP")
		if Input.is_action_just_pressed("%s_HP" % px):
			air_normal("HP")
		if Input.is_action_just_pressed("%s_LK" % px) and \
				Input.is_action_just_pressed("%s_LP" % px) == false:
			air_normal("LK")
		if Input.is_action_just_pressed("%s_MK" % px):
			air_normal("MK")
		if Input.is_action_just_pressed("%s_HK" % px):
			air_normal("HK")
	# Debug mode --------------------------------------------------------------
	if debug_mode == true:
		if Input.is_key_pressed(49):
			Engine.time_scale = 0.5
			Engine.iterations_per_second = 30
		if Input.is_key_pressed(50):
			Engine.time_scale = 1
			Engine.iterations_per_second = 60
		if Input.is_key_pressed(51):
			Engine.time_scale = 2
			Engine.iterations_per_second = 120

func normal_cancels():
	if can_auto_cancel == true:
		if Input.is_action_pressed("%s_DOWN" % px) and Input.is_action_just_pressed("%s_LP" % px):
			$AnimationPlayer.stop()
			crouching_normal("LP")
		elif Input.is_action_pressed("%s_DOWN" % px) and Input.is_action_just_pressed("%s_LK" % px):
			$AnimationPlayer.stop()
			crouching_normal("LK")
		elif Input.is_action_just_pressed("%s_LP" % px):
			$AnimationPlayer.stop()
			standing_normal("LP")
		elif Input.is_action_just_pressed("%s_LK" % px):
			$AnimationPlayer.stop()
			standing_normal("LK")
	if can_special_cancel == true:
		if $AnimationPlayer.current_animation == "Attack standing MK":
			if Input.is_action_just_pressed("%s_MP" % px):
				standing_normal("MP")

func trigger_special_1(): # HADOKEN
	if Input.is_action_just_pressed("%s_DOWN" % px):
		sp1_input_count = 1
		
	if sp1_input_count == 1:
		if must_face_right == true:
			if Input.is_action_pressed("%s_RIGHT" % px) and Input.is_action_pressed("%s_DOWN" % px):
				$SpecialTimer1.start()
				sp1_input_count = 2
		else:
			if Input.is_action_pressed("%s_LEFT" % px) and Input.is_action_pressed("%s_DOWN" % px):
				$SpecialTimer1.start()
				sp1_input_count = 2
			
	if sp1_input_count == 2:
		if must_face_right == true:
			if Input.is_action_pressed("%s_RIGHT" % px) and \
					Input.is_action_just_released("%s_DOWN" % px):
				sp1_input_count = 3
		else:
			if Input.is_action_pressed("%s_LEFT" % px) and \
					Input.is_action_just_released("%s_DOWN" % px):
				sp1_input_count = 3
			
	if sp1_input_count == 3:
		if Input.is_action_just_pressed("%s_LP" % px) and \
				Input.is_action_just_pressed("%s_MP" % px) \
				or Input.is_action_just_pressed("%s_LP" % px) and \
				Input.is_action_just_pressed("%s_HP" % px) \
				or Input.is_action_just_pressed("%s_MP" % px) and \
				Input.is_action_just_pressed("%s_HP" % px):
				if power_level >= 100:
					power_level -= 100
					hud.manage_power(player, power_level)
					special_1("Powered")
				else: pass
		if Input.is_action_just_pressed("%s_HP" % px):
			special_1("Heavy")
		if Input.is_action_just_pressed("%s_MP" % px):
			special_1("Medium")
		if Input.is_action_just_pressed("%s_LP" % px):
			special_1("Light")

func trigger_special_2(): # SHORYUKEN
	if must_face_right == true:
		if Input.is_action_just_released("%s_RIGHT" % px):
			$SpecialTimer2.start()
			sp2_input_count = 1
	else:
		if Input.is_action_just_released("%s_LEFT" % px):
			$SpecialTimer2.start()
			sp2_input_count = 1
		
	if sp2_input_count == 1:
		if Input.is_action_pressed("%s_DOWN" % px):
			sp2_input_count = 2
			
	if sp2_input_count == 2:
		if must_face_right == true:
			if Input.is_action_pressed("%s_DOWN" % px) and \
					Input.is_action_just_pressed("%s_RIGHT" % px):
				sp2_input_count = 3
		else:
			if Input.is_action_pressed("%s_DOWN" % px) and \
					Input.is_action_just_pressed("%s_LEFT" % px):
				sp2_input_count = 3
	
	if sp2_input_count == 3:
		if Input.is_action_just_pressed("%s_HP" % px):
			special_2("heavy")
		elif Input.is_action_just_pressed("%s_MP" % px):
			special_2("medium")
		elif Input.is_action_just_pressed("%s_LP" % px):
			special_2("light")

func trigger_special_3(delta): # TATSU
	if Input.is_action_pressed("%s_LEFT" % px):
			sp3_left_charge += 1 * delta
	if Input.is_action_pressed("%s_RIGHT" % px):
			sp3_right_charge += 1 * delta
	if Input.is_action_just_released("%s_LEFT" % px):
			yield(get_tree().create_timer(0.3, false), "timeout")
			sp3_left_charge = 0
	if Input.is_action_just_released("%s_RIGHT" % px):
			yield(get_tree().create_timer(0.3, false), "timeout")
			sp3_right_charge = 0
			
	if facing_right == true:
		if sp3_left_charge >= 1:
			if Input.is_action_pressed("%s_RIGHT" % px):
				if Input.is_action_just_pressed("%s_HK" % px):
					special_3("Heavy")
				if Input.is_action_just_pressed("%s_MK" % px):
					special_3("Medium")
				if Input.is_action_just_pressed("%s_LK" % px):
					special_3("Light")
	else:
		if sp3_right_charge >= 1:
			if Input.is_action_pressed("%s_LEFT" % px):
				if Input.is_action_just_pressed("%s_HK" % px):
					special_3("Heavy")
				if Input.is_action_just_pressed("%s_MK" % px):
					special_3("Medium")
				if Input.is_action_just_pressed("%s_LK" % px):
					special_3("Light")

func trigger_special_4(delta): # ONE HUNDRED SLAPS
	if sp4_slap_buffer > 0:
		sp4_slap_buffer -= 20 * delta
	if  sp4_slap_buffer < 50:
		if Input.is_action_just_pressed("%s_LP" % px) or \
				Input.is_action_just_pressed("%s_MP" % px) or \
				Input.is_action_just_pressed("%s_HP" % px):
			sp4_slap_buffer += 12
	if sp4_slap_buffer > 50:
		special_4()

func special_1(strenght):
	var fireball = Fireball.instance()
	var fireball_count
	
	if player == 1:
		fireball_count = get_tree().get_nodes_in_group("P1_projectiles")
	else: fireball_count = get_tree().get_nodes_in_group("P2_projectiles")

	sp1_input_count = 0
	can_auto_cancel = false
	if state == is_.STANDING or can_special_cancel == true:
		if fireball_count.size() == 0:
			if can_special_cancel == true:
				can_special_cancel = false
				$ProximityBox/ProxBox1.disabled = true
			state = is_.ATTACKING_SP
			$AnimationPlayer.play("Special 1")
			yield(get_tree().create_timer(0.1667, false), "timeout")
			if state != is_.GRABBED or state != is_.HIT_STUNNED_ST:
				if facing_right == true:
					fireball.position.x = self.position.x + 35
				else: fireball.position.x = self.position.x - 35
				fireball.position.y = self.position.y - 60
				fireball.set_as_toplevel(true)
				fireball.fireball_data(player, facing_right, strenght)
				add_child(fireball)
				if strenght != "Powered":
					power_level += power_sp_inc
					hud.manage_power(player, power_level)
				yield($AnimationPlayer, "animation_finished")
				stand()
		else: pass
	else: pass

func special_2(strenght):
	var shoryu_height = 60
	var shoryu_lenght = 40
	
	can_auto_cancel = false
	if facing_right == false:
		shoryu_lenght = -shoryu_lenght
	
	if state == is_.STANDING or state == is_.CROUCHING or can_special_cancel == true:
		if can_special_cancel == true:
			can_special_cancel = false
			$ProximityBox/ProxBox1.disabled = true
		state = is_.AIR_ATTACKING_SP
		tween.remove_all()
		strike_data(50, 180, 10, "Heavy", "Mid", "Special", 0, false)
		$AnimationPlayer.play("Special 2")
		yield(get_tree().create_timer(0.2, false), "timeout")
		if state == is_.AIR_ATTACKING_SP or state == is_.PRE_JUMP:
			strike_data(70, 180, 30, "Launch", "Mid", "Special", 0, false)
			tween.interpolate_property(self, "position:y",
					self.position.y, (self.position.y - shoryu_height),
					0.35, Tween.TRANS_QUINT, Tween.EASE_OUT)
			tween.interpolate_property(self, "position:x",
					self.position.x, (self.position.x + shoryu_lenght),
					0.2, Tween.TRANS_QUINT, Tween.EASE_OUT)
			tween.start()
			power_level += power_sp_inc
			hud.manage_power(player, power_level)
			$TweenTimer.start(0.35)
			yield($TweenTimer, "timeout")
			if state != is_.AIR_STUNNED:
				tween.interpolate_property(self, "position:y",
						self.position.y, (self.position.y + shoryu_height),
						0.35, Tween.TRANS_QUINT, Tween.EASE_IN)
				tween.start()
				$TweenTimer.start(0.35)
				yield($TweenTimer, "timeout")
				if state == is_.AIR_ATTACKING_SP:
					stand()
				else: return
			else: return
		else: return
	else: return

func special_3(strenght):
	var tatsu_lenght
	var tatsu_time
	var kicks_number
	
	can_auto_cancel = false
	if strenght == "Heavy":
		tatsu_lenght = 200
		tatsu_time = 1.119
		kicks_number = 3
	elif strenght == "Medium":
		tatsu_lenght = 130
		tatsu_time = 0.786
		kicks_number = 2
	else:
		tatsu_lenght = 100
		kicks_number = 1
		tatsu_time = 0.453
	if facing_right == false:
		tatsu_lenght = -tatsu_lenght
	
	if state == is_.STANDING or state == is_.CROUCHING or can_special_cancel == true:
		if can_special_cancel == true:
			can_special_cancel = false
			$ProximityBox/ProxBox1.disabled = true
		state = is_.AIR_ATTACKING_SP
		strike_data(60, 80, -60, strenght, "Mid", "Special", 0, false)
		$AnimationPlayer.stop(true)
		$AnimationPlayer.play("Special 3 start")
		yield(get_tree().create_timer(0.2, false), "timeout")
		if state != is_.AIR_STUNNED:
			for i in range(kicks_number):
				$AnimationPlayer.queue("Special 3 action")
			$AnimationPlayer.queue("Special 3 end")
			tween.interpolate_property(self, "position:x",
					self.position.x, (self.position.x + tatsu_lenght),
					tatsu_time, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
			tween.start()
			power_level += power_sp_inc
			hud.manage_power(player, power_level)
			$TweenTimer.start(tatsu_time)
			yield($TweenTimer, "timeout")
			if state != is_.AIR_STUNNED:
				tween.remove_all()
				stand()
	else: pass

func special_4():
	can_auto_cancel = false
	if state == is_.STANDING or state == is_.CROUCHING or can_special_cancel == true:
		if can_special_cancel == true:
			can_special_cancel = false
			$ProximityBox/ProxBox1.disabled = true
		state = is_.ATTACKING_SP
		sp4_slap_buffer = 0
		strike_data(30, 20, 10, "Medium", "Mid", "Special", 0, false)
		$AnimationPlayer.play("Special 4 start")
		power_level += power_sp_inc
		hud.manage_power(player, power_level)
		for i in range(3):
			$AnimationPlayer.queue("Special 4 action")
			yield($AnimationPlayer, "animation_finished")
		$AnimationPlayer.queue("Special 4 end")
		yield($AnimationPlayer, "animation_finished")
		if state == is_.ATTACKING_SP:
			stand()
	else: pass

func stand():
	if health_level > 0:
		state = is_.STANDING
		enable_hurt_boxes()
		is_walking_forward = false
		is_walking_backward = false
		self.z_index = 0
		if already_crouched == true:
			already_crouched = false
			$AnimationPlayer.play_backwards("Crouch")
			$AnimationPlayer.queue("Stand")
		else: $AnimationPlayer.play("Stand")
	else:
		state = is_.LOCKED
		$AnimationPlayer.play("Exhausted")
		yield($AnimationPlayer, "animation_finished")
		yield(get_tree().create_timer(1), "timeout")
		rival.player_wins()

func crouch():
	if health_level >0:
		state = is_.CROUCHING
		dash_l_ready = false
		dash_r_ready = false
		if already_crouched == false:
			already_crouched = true
			$AnimationPlayer.play("Crouch")
			yield($AnimationPlayer, "animation_finished")
		$AnimationPlayer.play("Crouch already")
	else:
		$AnimationPlayer.play("Exhausted")
		$AnimationPlayer.seek(0.333)
		yield($AnimationPlayer, "animation_finished")
		yield(get_tree().create_timer(1), "timeout")
		rival.player_wins()

func walk_forward(delta):
	$AnimationPlayer.play("Walk forward")
	is_walking_forward = true
	if pushray.is_colliding() == false:
		self.position.x += walk_forward_speed * delta
	else:
		if rival.is_stuck == false:
			if rival.is_walking_backward == false:
				self.position.x += walk_forward_speed / 2 * delta
			else: self.position.x += walk_forward_speed * delta
		else: pass

func walk_backward(delta):
	$AnimationPlayer.play("Walk backward")
	is_walking_backward = true
	self.position.x -= walk_backward_speed * delta
	
func jump_vertical():
	tween.remove_all()
	#Arco ascendente --------------------------------
	if state == is_.PRE_JUMP or state == is_.AIR_ATTACKING:
		if state != is_.AIR_ATTACKING:
			$AnimationPlayer.play("Jump vertical")
		tween.interpolate_property(self, "position:y",
				self.position.y, (self.position.y - jump_height),
				jump_asc_time, Tween.TRANS_QUINT, Tween.EASE_OUT)
		tween.start()
		state = is_.JUMPING
		$TweenTimer.start(jump_asc_time)
		yield($TweenTimer, "timeout")
		#Arco descendente -------------------------------
		if state != is_.AIR_STUNNED and state != is_.GRABBING and state != is_.GRABBED\
						and state != is_.LOCKED:
			tween.interpolate_property(self, "position:y",
					self.position.y, (self.position.y + jump_height),
					jump_des_time, Tween.TRANS_QUINT, Tween.EASE_IN)
			tween.start()
			$TweenTimer.start(jump_des_time)
			yield($TweenTimer, "timeout")
			if state != is_.AIR_STUNNED and state != is_.GRABBING and state != is_.GRABBED\
						and state != is_.LOCKED:
				disable_hit_boxes()
				stand()
			else: return
		else: return
	else: return

func jump_forward():
	tween.remove_all()
	#Arco ascendente --------------------------------
	if state == is_.PRE_JUMP or state == is_.AIR_ATTACKING:
		if state != is_.AIR_ATTACKING:
			$AnimationPlayer.play("Jump forward")
		tween.interpolate_property(self, "position:x",
				self.position.x, self.position.x + jump_f_lenght / 2,
				jump_asc_time, Tween.TRANS_LINEAR, Tween.EASE_OUT)
		tween.interpolate_property(self, "position:y",
				self.position.y, self.position.y - jump_height,
				jump_asc_time, Tween.TRANS_QUINT, Tween.EASE_OUT)
		tween.start()
		state = is_.JUMPING
		is_jumping_forward = true
		is_walking_forward = false
		$TweenTimer.start(jump_asc_time)
		yield($TweenTimer, "timeout")
		#Arco descendente -------------------------------
		if state != is_.AIR_STUNNED and state != is_.GRABBING and state != is_.GRABBED \
						and state != is_.LOCKED:
			tween.interpolate_property(self, "position:x",
					self.position.x, self.position.x + jump_f_lenght / 2,
					jump_des_time, Tween.TRANS_LINEAR, Tween.EASE_IN)
			tween.interpolate_property(self, "position:y",
					self.position.y, self.position.y + jump_height,
					jump_des_time, Tween.TRANS_QUINT, Tween.EASE_IN)
			tween.start()
			$TweenTimer.start(jump_des_time)
			yield($TweenTimer, "timeout")
			if state != is_.AIR_STUNNED and state != is_.GRABBING and state != is_.GRABBED \
						and state != is_.LOCKED:
				tween.remove_all()
				disable_hit_boxes()
				stand()
			else: return
		else: return
	else: return

func jump_backward():
	tween.remove_all()
	#Arco ascendente --------------------------------
	if state == is_.PRE_JUMP or state == is_.AIR_ATTACKING:
		if state != is_.AIR_ATTACKING:
			$AnimationPlayer.play("Jump backward")
		tween.interpolate_property(self, "position:x",
				self.position.x, self.position.x - jump_b_lenght / 2,
				jump_asc_time, Tween.TRANS_LINEAR, Tween.EASE_OUT)
		tween.interpolate_property(self, "position:y",
				self.position.y, self.position.y - jump_height,
				jump_des_time, Tween.TRANS_QUINT, Tween.EASE_OUT)
		tween.start()
		state = is_.JUMPING
		is_jumping_backward = true
		is_walking_backward = false
		$TweenTimer.start(jump_asc_time)
		yield($TweenTimer, "timeout")
		#Arco descendente -------------------------------
		if state != is_.AIR_STUNNED  and state != is_.GRABBING and state != is_.GRABBED \
					and state != is_.LOCKED:
			tween.interpolate_property(self, "position:x",
					self.position.x, self.position.x - jump_b_lenght / 2,
					jump_des_time, Tween.TRANS_LINEAR, Tween.EASE_IN)
			tween.interpolate_property(self, "position:y",
					self.position.y, self.position.y + jump_height,
					jump_des_time, Tween.TRANS_QUINT, Tween.EASE_IN)
			tween.start()
			$TweenTimer.start(jump_des_time)
			yield($TweenTimer, "timeout")
			if state != is_.AIR_STUNNED and state != is_.GRABBING and state != is_.GRABBED \
						and state != is_.LOCKED:
				tween.remove_all()
				disable_hit_boxes()
				stand()
			else: return
		else: return
	else: return

func dash_forward():
	$AnimationPlayer.play("Dash forward")
	is_walking_forward = false
	is_dashing_forward = true
	if pushray.is_colliding() == false:
		tween.interpolate_property(self, "position:x", self.position.x,
				self.position.x + dash_f_dist, dash_f_time,
				Tween.TRANS_QUART, Tween.EASE_OUT)
	else:
		tween.interpolate_property(self, "position:x", self.position.x,
				self.position.x + dash_f_dist / 2, dash_f_time,
				Tween.TRANS_QUART, Tween.EASE_OUT)
	tween.start()
	state = is_.DASHING
	$TweenTimer.start(dash_f_time)
	yield($TweenTimer, "timeout")
	if state != is_.AIR_STUNNED and state != is_.GRABBING and state != is_.GRABBED \
				and state != is_.LOCKED:
		tween.remove_all()
		stand()
	else: pass

func dash_backward():
	$AnimationPlayer.play("Dash backward")
	is_walking_backward = false
	is_dashing_backward = true
	tween.interpolate_property(self, "position:x", self.position.x,
			self.position.x - dash_b_dist, dash_b_time,
			Tween.TRANS_QUINT, Tween.EASE_OUT)
	tween.start()
	state = is_.DASHING
	$TweenTimer.start(dash_b_time)
	yield($TweenTimer, "timeout")
	if state != is_.AIR_STUNNED and state != is_.GRABBING and state != is_.GRABBED \
				and state != is_.LOCKED:
		tween.remove_all()
		stand()
	else: pass

func set_false_to_dash_forward():
	is_dashing_forward = false # Probar restar un tween al colisionar dashes

func standing_normal(button_pressed):
	state = is_.ATTACKING_ST
	startup_frames = true
	if button_pressed == "LP":
		strike_data(30, 80, 20, "Light", "Mid", "Normal", 2, false)
		$AnimationPlayer.play("Attack standing LP")
	if button_pressed == "MP":
		strike_data(60, 140, 30, "Medium", "Mid", "Normal", 1, false)
		$AnimationPlayer.play("Attack standing MP")
	if button_pressed == "HP":
		strike_data(90, 190, 40, "Heavy", "Mid", "Normal", 1, false)
		$AnimationPlayer.play("Attack standing HP")
	if button_pressed == "LK":
		strike_data(30, 90, 20, "Light", "Mid", "Normal", 2, false)
		$AnimationPlayer.play("Attack standing LK")
	if button_pressed == "MK":
		strike_data(60, 170, 30, "Medium", "Mid", "Normal", 1, true)
		$AnimationPlayer.play("Attack standing MK")
	if button_pressed == "HK":
		strike_data(50, 210, 20, "Heavy", "Mid", "Normal", 0, false)
		$AnimationPlayer.play("Attack standing HK")
	$StrikeTimer.start($AnimationPlayer.current_animation_length)
	yield($StrikeTimer, "timeout")
	if state == is_.ATTACKING_ST:
		stand()
	else: pass

func crouching_normal(button_pressed):
	state = is_.ATTACKING_CR
	startup_frames = true
	already_crouched = true
	if button_pressed == "LP":
		strike_data(30, 90, 15, "Light", "Low", "Normal", 2, false)
		$AnimationPlayer.play("Attack crouching LP")
	if button_pressed == "MP":
		strike_data(60, 140, 30, "Medium", "Low", "Normal", 1, false)
		$AnimationPlayer.play("Attack crouching MP")
	if button_pressed == "HP":
		strike_data(90, 190, 40, "Launch", "Low", "Special", 1, false)
		$AnimationPlayer.play("Attack crouching HP")
	if button_pressed == "LK":
		strike_data(30, 90, 15, "Light", "Low", "Normal", 2, false)
		$AnimationPlayer.play("Attack crouching LK")
	if button_pressed == "MK":
		strike_data(60, 170, 30, "Medium", "Low", "Normal", 1, false)
		$AnimationPlayer.play("Attack crouching MK")
	if button_pressed == "HK":
		strike_data(90, 210, 40, "Sweep", "Low", "Normal", 0, false)
		$AnimationPlayer.play("Attack crouching HK")
	$StrikeTimer.start($AnimationPlayer.current_animation_length)
	yield($StrikeTimer, "timeout")
	if state == is_.ATTACKING_CR:
		crouch()
	else: pass

func air_normal(button_pressed):
	state = is_.AIR_ATTACKING
	startup_frames = true
	if button_pressed == "LP":
		strike_data(40, 90, 20, "Light", "High", "Normal", 0, false)
		$AnimationPlayer.play("Attack jumping LP")
	if button_pressed == "MP":
		strike_data(70, 140, 30, "Medium", "High", "Normal", 0, false)
		$AnimationPlayer.play("Attack jumping MP")
	if button_pressed == "HP":
		strike_data(100, 190, 40, "Heavy", "High", "Normal", 0, false)
		$AnimationPlayer.play("Attack jumping HP")
	if button_pressed == "LK":
		strike_data(40, 90, 20, "Light", "High", "Normal", 0, false)
		$AnimationPlayer.play("Attack jumping LK")
	if button_pressed == "MK":
		strike_data(70, 170, 30, "Medium", "High", "Normal", 0, false)
		$AnimationPlayer.play("Attack jumping MK")
	if button_pressed == "HK":
		strike_data(100, 210, 40, "Heavy", "High", "Normal", 0, false)
		$AnimationPlayer.play("Attack jumping HK")

func overhead():
	state = is_.AIR_ATTACKING
	startup_frames = true
	strike_data(50, 50, 50, "Heavy", "High", "Normal", 0, false)
	$AnimationPlayer.play("Overhead")
	$StrikeTimer.start($AnimationPlayer.current_animation_length)
	yield(get_tree().create_timer(0.2), "timeout")
	if state == is_.AIR_ATTACKING:
		tween_parable(80, 20, 0.3)
	yield($StrikeTimer, "timeout")
	if state == is_.AIR_ATTACKING:
		stand()

func strike_data(damg, stun, push, strg, area, type, canc, jugg):
	hit_damg = damg
	hit_stun = stun
	hit_push = push
	hit_strg = strg
	hit_area = area
	hit_type = type
	hit_canc = canc
	hit_jugg = jugg

func grab_attempt():
	state = is_.ATTACKING_ST
	$GrabCounterTimer.start(0.100)
	$AnimationPlayer.play("Grab attempt")
		
func air_grab_attempt():
	state = is_.AIR_ATTACKING
	$GrabBox/GrabBox1.disabled = false
	yield(get_tree().create_timer(0.2, false), "timeout")
	$GrabBox/GrabBox1.disabled = true

func grab():
	if rival.state == is_.STANDING or rival.state == is_.CROUCHING or \
				rival.state == is_.ATTACKING_ST or rival.state == is_.ATTACKING_CR or \
				rival.state == is_.DASHING:
		state = is_.GRABBING
		$AnimationPlayer.stop(true)
		$GrabBox/GrabBox1.set_deferred("disabled", true)
		rival.grabbed()
		if facing_right == true:
			if Input.is_action_pressed("%s_LEFT" % px):
				backward_grab()
			else: forward_grab()
		else:
			if Input.is_action_pressed("%s_RIGHT" % px):
				backward_grab()
			else: forward_grab()
	else: 
		yield($AnimationPlayer, "animation_finished")
		stand()

func air_grab():
	var rival_sprite = rival.get_node("Sprite")
	state = is_.GRABBING
	rival.grabbed()
	tween.remove_all()
	$AnimationPlayer.stop(true)
	self.z_index = 1
	$Sprite.frame = 306
	rival_sprite.frame = 94
	if facing_right == true:
		rival.position = self.position + Vector2(20, -10)
	else: rival.position = self.position + Vector2(-20, -10)
	yield(get_tree().create_timer(0.3, false), "timeout")
	tween.interpolate_property(self, "position:y",
			self.position.y, (stage_size.end.y - 20),
			0.5, Tween.TRANS_QUINT, Tween.EASE_IN)
	tween.start()
	$Sprite.frame = 379
	rival_sprite.frame = 93
	rival_sprite.flip_v = true
	rival.position_is_locked = true
	rival.grab_offset = Vector2(0, 15)
	yield(tween, "tween_completed")
	rival.position_is_locked = false
	rival.grab_offset = Vector2(0, 0)
	$Sprite.frame = 381
	rival_sprite.flip_v = false
	rival_sprite.flip_h = true
	rival_sprite.frame = 95
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
	
func grabbed():
	state = is_.GRABBED
	tween.remove_all()
	$AnimationPlayer.stop(true)
	disable_hit_boxes()
	knockdown_level = 2
	if state == is_.JUMPING or state == is_.AIR_ATTACKING:
		pass
	else:
		$Sprite.frame = 89

func forward_grab():
	print("No forward grab implemented")
	
func backward_grab():
	print("No backward grab implemented")

func lock_position():
	var grab_position
	grab_position = rival.position + grab_offset
	if facing_right == false:
		grab_position.x = rival.position.x + grab_offset.x
	else: grab_position.x = rival.position.x - grab_offset.x
	if position_is_locked == true:
		self.position = grab_position
		state = is_.LOCKED
	else:
		pass

func throwed(distance, height):
	tween.remove_all()
	if facing_right == false:
		distance = -distance
	#Arco ascendente --------------------------------
	tween.interpolate_property(self, "position:x",
		self.position.x, self.position.x + distance / 2,
		0.2, Tween.TRANS_LINEAR, Tween.EASE_OUT)
	tween.interpolate_property(self, "position:y",
		self.position.y, self.position.y - height,
		0.2, Tween.TRANS_QUINT, Tween.EASE_OUT)
	tween.start()
	state = is_.AIR_STUNNED
	yield(tween, "tween_all_completed")
	#Arco descendente -------------------------------
	tween.interpolate_property(self, "position:x",
		self.position.x, self.position.x + distance / 2,
		0.2, Tween.TRANS_LINEAR, Tween.EASE_IN)
	tween.interpolate_property(self, "position:y",
		self.position.y, self.position.y + 500,
		0.2, Tween.TRANS_QUINT, Tween.EASE_IN)
	tween.start()
	yield(tween, "tween_all_completed")

func grab_countered():
	$GrabBox/GrabBox1.set_deferred("disabled", true)
#	$AnimationPlayer.stop(true)
#	tween.stop_all()
	state = is_.HIT_STUNNED_ST
	knockback(30)
	$AnimationPlayer.play("Grab countered")
	yield($AnimationPlayer, "animation_finished")
	stand()
	
func grab_escape():
#	$AnimationPlayer.stop()
	rival.grab_countered()
	state = is_.HIT_STUNNED_ST
	tween_parable(-50, 10, 0.4)
	$AnimationPlayer.play("Grab scape")
	yield($AnimationPlayer, "animation_finished")
	stand()

func concurrent_grab():
	if nearly_grabbed == true and rival.nearly_grabbed == true:
		if state != is_.AIR_ATTACKING:
			grab_countered()

func block_standing():
	state = is_.BLOCKING_H
	$AnimationPlayer.play("Block standing")

func block_crouching():
	state = is_.BLOCKING_L
	already_crouched = true
	$AnimationPlayer.play("Block crouching")
	
func _on_hit_connects(area):
	if area.has_method("fighter_hurt_box"):
		$HitBoxes/HitBox1.set_deferred("disabled", true)
		if state == is_.ATTACKING_ST or state == is_.ATTACKING_CR or state == is_.AIR_ATTACKING:
			if hit_canc >= 1:
				can_special_cancel = true
			if hit_canc >= 3:
				can_normal_cancel = true
			yield(get_tree().create_timer(0.0001), "timeout")
			var hit_freeze
			if hit_strg == "Light":
				hit_freeze = FREEZE_LIGHT
			elif hit_strg == "Medium":
				hit_freeze = FREEZE_MEDIUM
			else: hit_freeze = FREEZE_HEAVY
			power_level += hit_damg / 6
			hud.manage_power(player, power_level)
			$AnimationPlayer.stop(false)
			$Tween.stop_all()
			$StrikeTimer.set_paused(true)
			$TweenTimer.set_paused(true)
			yield(get_tree().create_timer(hit_freeze, true), "timeout")
			$AnimationPlayer.play()
			$Tween.resume_all()
			$StrikeTimer.set_paused(false)
			$TweenTimer.set_paused(false)

func on_hit():
	$HitBoxes/HitBox1.set_deferred("disabled", true)
	$ProximityBox/ProxBox1.set_deferred("disabled", true)
	is_walking_forward = false
	is_dashing_forward = false
	if state == is_.BLOCKING_H or state == is_.BLOCK_STUNNED_H:
		if damaging_area.hit_area == "High" or damaging_area.hit_area == "Mid":
			blocked_hit()
		else:
			received_hit()

	elif state == is_.BLOCKING_L or state == is_.BLOCK_STUNNED_L:
		if damaging_area.hit_area == "Mid" or damaging_area.hit_area == "Low":
			blocked_hit()
		else: received_hit()

	elif state == is_.JUMPING or state == is_.DASHING or \
			state == is_.AIR_ATTACKING or state == is_.AIR_ATTACKING_SP:
		air_received_hit(false)
		
	elif state == is_.AIR_STUNNED:
		if damaging_area.hit_jugg == true:
			air_received_hit(false)
		else: pass

	else:
		received_hit()
		
func on_hit_freeze():
	yield(get_tree().create_timer(0.0001), "timeout")
	var hit_freeze
	if damaging_area.hit_strg == "Light":
		hit_freeze = FREEZE_LIGHT
	elif damaging_area.hit_strg == "Medium":
		hit_freeze = FREEZE_MEDIUM
	else: hit_freeze = FREEZE_HEAVY
	if damaging_area != rival:
		damaging_area.on_hit_freeze(hit_freeze)
	hit_shake()
	$AnimationPlayer.stop(false)
	$Tween.stop_all()
	$TweenTimer.set_paused(true)
	yield(get_tree().create_timer(hit_freeze), "timeout")
	$AnimationPlayer.play()
	$Tween.resume_all()
	$TweenTimer.set_paused(false)
	is_shaked = false
	
func hit_shake():
	is_shaked = true
	if is_shaked == true:
		$Sprite.position.x += 3
		yield(get_tree().create_timer(0.0167), "timeout")
		$Sprite.position.x -= 3
		yield(get_tree().create_timer(0.0167), "timeout")
	if is_shaked == false:
		$Sprite.position.x = 0
	else: hit_shake()
	
func blocked_hit():
	get_parent().play_hitfx(facing_right, hitfx_area_rect, "Blocked", damaging_area.hit_strg)
	power_level += damaging_area.hit_damg / 8
	hud.manage_power(player, power_level)
	if damaging_area.has_method("disable_projectile"):
		damaging_area.disable_projectile()
	if damaging_area.hit_type != "Normal":
		calculate_damage(true)
	if state == is_.BLOCKING_H or state == is_.BLOCK_STUNNED_H:
		state = is_.BLOCK_STUNNED_H
		if hitted_area == "Head":
			if damaging_area.hit_strg == "Light":
				$AnimationPlayer.play("Block stun high light")
				knockback(damaging_area.hit_push)
			elif damaging_area.hit_strg == "Medium":
				$AnimationPlayer.play("Block stun high medium")
				knockback(damaging_area.hit_push)
			else:
				$AnimationPlayer.play("Block stun high heavy")
				knockback(damaging_area.hit_push)
		else:
			if damaging_area.hit_strg == "Light":
				$AnimationPlayer.play("Block stun low light")
				knockback(damaging_area.hit_push)
			elif damaging_area.hit_strg == "Medium":
				$AnimationPlayer.play("Block stun low medium")
				knockback(damaging_area.hit_push)
			else:
				$AnimationPlayer.play("Block stun low heavy")
				knockback(damaging_area.hit_push)
	elif state == is_.BLOCKING_L or state == is_.BLOCK_STUNNED_L:
		state = is_.BLOCK_STUNNED_L
		if damaging_area.hit_strg == "Light":
			$AnimationPlayer.play("Block stun crouching light")
			knockback(damaging_area.hit_push)
		elif rival.hit_strg == "Medium":
			$AnimationPlayer.play("Block stun crouching medium")
			knockback(damaging_area.hit_push)
		else:
			$AnimationPlayer.play("Block stun crouching heavy")
			knockback(damaging_area.hit_push)
	on_hit_freeze()
	yield($Tween, "tween_completed")
	if cpu_level != 0:
		$CPUMove.start(rand_range(0, 1))
		cpu_move = do_.STAND
	if state == is_.BLOCK_STUNNED_L:
		crouch()
	else: stand()
	changed_guard = false

func received_hit():
	disable_hit_boxes()
	combo_counter += 1
	calculate_damage(false)
	power_level += damaging_area.hit_damg / 6
	hud.manage_power(player, power_level)
	if damaging_area.has_method("disable_projectile"):
		damaging_area.disable_projectile()
	if state == is_.CROUCHING or state == is_.ATTACKING_CR or state == is_.BLOCKING_L or \
			state == is_.BLOCK_STUNNED_L or state == is_.HIT_STUNNED_CR:
		get_parent().play_hitfx(facing_right, hitfx_area_rect, "Connected", damaging_area.hit_strg)
		state = is_.HIT_STUNNED_CR
		$AnimationPlayer.stop()
		already_crouched = true
		if damaging_area.hit_strg == "Light":
			$AnimationPlayer.play("Hit stun crouching light")
			knockback(damaging_area.hit_push)
		elif damaging_area.hit_strg == "Medium":
			$AnimationPlayer.play("Hit stun crouching medium")
			knockback(damaging_area.hit_push)
		elif damaging_area.hit_strg == "Heavy":
			$AnimationPlayer.play("Hit stun crouching heavy")
			knockback(damaging_area.hit_push)
		elif damaging_area.hit_strg == "Sweep":
			knocked_down()
		else: air_received_hit(true)
		yield($Tween, "tween_completed")
		if cpu_level != 0:
			$CPUMove.start(rand_range(0, 1))
			cpu_move = do_.STAND
		if state != is_.KNOCKED_DOWN and state != is_.AIR_STUNNED:
			crouch()
		
	if state == is_.STANDING or state == is_.ATTACKING_ST or state == is_.ATTACKING_SP or \
			state == is_.BLOCKING_H or state == is_.HIT_STUNNED_ST or \
			state == is_.BLOCK_STUNNED_H or state == is_.LOCKED or state == is_.PRE_JUMP:
		get_parent().play_hitfx(facing_right, hitfx_area_rect, "Connected", damaging_area.hit_strg)
		state = is_.HIT_STUNNED_ST
		$AnimationPlayer.stop()
		if hitted_area == "Head":
			if damaging_area.hit_strg == "Light":
				$AnimationPlayer.play("Hit stun head light")
				knockback(damaging_area.hit_push)
			elif damaging_area.hit_strg == "Medium":
				$AnimationPlayer.play("Hit stun head medium")
				knockback(damaging_area.hit_push)
			elif damaging_area.hit_strg == "Heavy":
				$AnimationPlayer.play("Hit stun head heavy")
				knockback(damaging_area.hit_push)
			elif damaging_area.hit_strg == "Sweep":
				knocked_down()
			else: air_received_hit(true)
		elif hitted_area == "Torso":
			if damaging_area.hit_strg == "Light":
				$AnimationPlayer.play("Hit stun torso light")
				knockback(damaging_area.hit_push)
			elif damaging_area.hit_strg == "Medium":
				$AnimationPlayer.play("Hit stun torso medium")
				knockback(damaging_area.hit_push)
			elif damaging_area.hit_strg == "Heavy":
				$AnimationPlayer.play("Hit stun torso heavy")
				knockback(damaging_area.hit_push)
			elif damaging_area.hit_strg == "Sweep":
				knocked_down()
			else: air_received_hit(true)
		elif hitted_area == "Legs":
			if damaging_area.hit_strg == "Light":
				$AnimationPlayer.play("Hit stun legs light")
				knockback(damaging_area.hit_push)
			elif damaging_area.hit_strg == "Medium":
				$AnimationPlayer.play("Hit stun legs medium")
				knockback(damaging_area.hit_push)
			elif damaging_area.hit_strg == "Heavy":
				$AnimationPlayer.play("Hit stun legs heavy")
				knockback(damaging_area.hit_push)
			elif damaging_area.hit_strg == "Sweep":
				knocked_down()
			else: air_received_hit(true)
		on_hit_freeze()
		yield($Tween, "tween_completed")
		if cpu_level != 0:
			$CPUMove.start(rand_range(0, 1))
			cpu_move = do_.STAND
		if state != is_.WAKING_UP and state != is_.AIR_STUNNED:
			stand()
	else: pass
	
func knockback(distance):
	var no_surplus = false
	var time = $AnimationPlayer.current_animation_length 
	
	if distance < 0:
		no_surplus = true
		distance = -distance

	if no_surplus == false and rival == damaging_area:
		if self.position.x + distance > camera_pos.x + 172:
			rival.knockback_surplus((self.position.x + distance) - (camera_pos.x + 172))
		elif self.position.x - distance < camera_pos.x - 172:
			rival.knockback_surplus((self.position.x + distance) - (camera_pos.x - 172))
	tween.remove_all()
	if must_face_right == false:
		distance = -distance
	tween.interpolate_property(self, "position:x", self.position.x,
		self.position.x - distance, time,
		Tween.TRANS_QUINT, Tween.EASE_OUT)
	tween.start()

func knockback_surplus(distance):
	var time = $AnimationPlayer.current_animation_length - \
			$AnimationPlayer.current_animation_position
	if must_face_right == false:
		distance = -distance
	if state == is_.ATTACKING_ST or state == is_.ATTACKING_CR or state == is_.ATTACKING_SP:
		tween.remove_all()
		tween.interpolate_property(self, "position:x", self.position.x,
			self.position.x - distance, time,
			Tween.TRANS_QUINT, Tween.EASE_OUT)
		tween.start()
	if state == is_.AIR_ATTACKING or state == is_.AIR_ATTACKING_SP:
		tween.stop(self, "position:x")
		tween.interpolate_property(self, "position:x", self.position.x,
			self.position.x - distance, time,
			Tween.TRANS_QUINT, Tween.EASE_OUT)
		tween.start()
	else: pass

func knocked_down():
	state = is_.KNOCKED_DOWN
	$AnimationPlayer.play("Knockdown")
	knockback(50)
	yield($AnimationPlayer, "animation_finished")
	wake_up()

func air_received_hit(from_ground):
	var hit_impulse = airborne_hit_lenght
	disable_hit_boxes()
	if waiting_for_flip == true:
		hit_impulse = -hit_impulse
	if from_ground == false:
		combo_counter += 1
		get_parent().play_hitfx(facing_right, hitfx_area_rect, "Connected", damaging_area.hit_strg)
	else: pass
	calculate_damage(false)
	power_level += damaging_area.hit_damg / 6
	hud.manage_power(player, power_level)
	if damaging_area.has_method("disable_projectile"):
		damaging_area.disable_projectile()
	tween.remove_all()
	$AnimationPlayer.stop()
	if damaging_area.hit_type == "Normal" and knockdown_level == 0 and health_level > 0:
		$AnimationPlayer.play("Hit stun air soft")
	else:
		$AnimationPlayer.play("Hit stun air hard")
		if damaging_area.hit_type == "Special":
			knockdown_level = 1
		else: knockdown_level = 2
	state = is_.AIR_STUNNED
	on_hit_freeze()
	#Arco ascendente --------------------------------
	tween.interpolate_property(self, "position:x",
		self.position.x, self.position.x - hit_impulse / 2,
		0.4, Tween.TRANS_LINEAR, Tween.EASE_OUT)
	tween.interpolate_property(self, "position:y",
		self.position.y, self.position.y - 50,
		0.4, Tween.TRANS_QUINT, Tween.EASE_OUT)
	tween.start()
	$TweenTimer.start(0.4)
	yield($TweenTimer, "timeout")
	#Arco descendente -------------------------------
	tween.interpolate_property(self, "position:x",
		self.position.x, self.position.x - hit_impulse / 2,
		0.4, Tween.TRANS_LINEAR, Tween.EASE_IN)
	tween.interpolate_property(self, "position:y",
		self.position.y, self.position.y + 500,
		0.4, Tween.TRANS_QUINT, Tween.EASE_IN)
	tween.start()

func fall():
	if state == is_.AIR_STUNNED:
		if self.position.y == stage_size.end.y - 20:
			if knockdown_level == 0:
				stand()
			else:
				tween.remove_all()
				ground_impact()

func ground_impact():
	state = is_.GROUND_IMPACT
	$AnimationPlayer.play("Ground impact")
	if facing_right == must_face_right:
		tween.interpolate_property(self, "position:x", self.position.x,
			self.position.x - ground_impact_lenght, 0.5,
			Tween.TRANS_QUINT, Tween.EASE_OUT)
	else: 
		tween.interpolate_property(self, "position:x", self.position.x,
		self.position.x + ground_impact_lenght, 0.5,
		Tween.TRANS_QUINT, Tween.EASE_OUT)
	tween.start()
	yield($AnimationPlayer, "animation_finished")
	wake_up()

func wake_up():
	var rolling_direction
	rolling_direction = rolling_back_dist
	if health_level > 0:
		if waiting_for_flip == true:
			rolling_direction = -rolling_direction
		state = is_.WAKING_UP
		if knockdown_level < 2:
			if Input.is_action_pressed("%s_LEFT" % px) and must_face_right == true or \
							Input.is_action_pressed("%s_RIGHT" % px) and must_face_right == false:
				$AnimationPlayer.play("Rolling back")
				tween.interpolate_property(self, "position:x", self.position.x,
					self.position.x - rolling_direction, 0.3,
					Tween.TRANS_LINEAR, Tween.EASE_OUT)
				tween.start()
				yield(tween, "tween_completed")
			elif Input.is_action_pressed("%s_DOWN" % px):
				yield(get_tree().create_timer(0.8, false), "timeout")
			else: pass
		else: pass
		knockdown_level = 0
		$AnimationPlayer.play("Wake up")
		yield($AnimationPlayer, "animation_finished")
		if $Sprite.flip_h == true:
			$Sprite.flip_h = false
		stand()
	else:
		state = is_.LOCKED
		rival.state = is_.LOCKED
		yield(get_tree().create_timer(1), "timeout")
		rival.player_wins()

func tween_linear(distance, linear, time):
	if facing_right == false:
		distance = -distance
	if linear == true:
		tween.interpolate_property(self, "position:x",
			self.position.x, self.position.x + distance,
			time, Tween.TRANS_LINEAR, Tween.EASE_OUT)
	else:
		tween.interpolate_property(self, "position:x",
			self.position.x, self.position.x + distance,
			time, Tween.TRANS_QUINT, Tween.EASE_OUT)
	tween.start()
		
func tween_parable(distance, height, time):
	var actual_state = state
	if facing_right == false:
		distance = -distance
	#Arco ascendente --------------------------------
	tween.interpolate_property(self, "position:x",
		self.position.x, self.position.x + distance / 2,
		time / 2, Tween.TRANS_LINEAR, Tween.EASE_OUT)
	tween.interpolate_property(self, "position:y",
		self.position.y, self.position.y - height,
		time / 2, Tween.TRANS_QUINT, Tween.EASE_OUT)
	tween.start()
	yield(tween, "tween_all_completed")
	#Arco descendente -------------------------------
	if state == actual_state:
		tween.interpolate_property(self, "position:x",
			self.position.x, self.position.x + distance / 2,
			time / 2, Tween.TRANS_LINEAR, Tween.EASE_IN)
		tween.interpolate_property(self, "position:y",
			self.position.y, self.position.y + height,
			time / 2, Tween.TRANS_QUINT, Tween.EASE_IN)
		tween.start()
	else: pass
	
func boxes_auto_visibility():
	if $HitBoxes/HitBox1.disabled == true:
		$HitBoxes/HitBox1.visible = false
	else: $HitBoxes/HitBox1.visible = true
	
	if $HurtBoxes/HurtBox1.disabled == true:
		$HurtBoxes/HurtBox1.visible = false
	else: $HurtBoxes/HurtBox1.visible = true
	
	if $HurtBoxes/HurtBox2.disabled == true:
		$HurtBoxes/HurtBox2.visible = false
	else: $HurtBoxes/HurtBox2.visible = true
	
	if $HurtBoxes/HurtBox3.disabled == true:
		$HurtBoxes/HurtBox3.visible = false
	else: $HurtBoxes/HurtBox3.visible = true
	
	if $HurtBoxes/HurtBox4.disabled == true:
		$HurtBoxes/HurtBox4.visible = false
	else: $HurtBoxes/HurtBox4.visible = true
	
	if $ProximityBox/ProxBox1.disabled == true:
		$ProximityBox/ProxBox1.visible = false
	else: $ProximityBox/ProxBox1.visible = true
	
	if $GrabBox/GrabBox1.disabled == true:
		$GrabBox/GrabBox1.visible = false
	else: $GrabBox/GrabBox1.visible = true

func enable_hurt_boxes():
	$HurtBoxes/HurtBox1.disabled = false
	$HurtBoxes/HurtBox2.disabled = false
	$HurtBoxes/HurtBox3.disabled = false

func disable_hurt_boxes():
	$HurtBoxes/HurtBox1.disabled = true
	$HurtBoxes/HurtBox2.disabled = true
	$HurtBoxes/HurtBox3.disabled = true
	$HurtBoxes/HurtBox4.disabled = true

func disable_hit_boxes():
	$HitBoxes/HitBox1.set_deferred("disabled", true)
	$ProximityBox/ProxBox1.set_deferred("disabled", true)
	$GrabBox/GrabBox1.set_deferred("disabled", true)
	
func re_check_states():
	if state != is_.STANDING:
		is_walking_forward = false
		is_walking_backward = false
	if state != is_.JUMPING:
		is_jumping_forward = false
		is_jumping_backward = false
	if state != is_.DASHING:
		is_dashing_forward = false
		is_dashing_backward = false
	if state == is_.GRABBING or state == is_.GRABBED:
		$PushBox.disabled = true
		pushray.enabled = false
	else:
		$PushBox.disabled = false
		pushray.enabled = true
		
func pass_info_to_hud():
	if state == is_.STANDING or state == is_.CROUCHING \
			or state == is_.GROUND_IMPACT or state == is_.LOCKED:
		if combo_counter > 0:
			hud.combo_ended(player, combo_counter, health_level, false)
			combo_counter = 0
	if state == is_.HIT_STUNNED_ST or state == is_.HIT_STUNNED_CR or state == is_.AIR_STUNNED:
		if startup_frames == true:
			hud.show_info(player, "Counter!")

func counter_and_cancelling():
	if $HitBoxes/HitBox1.disabled == false:
		startup_frames = false
	if $HitBoxes/HitBox1.disabled == false and hit_canc == 2:
		can_auto_cancel = true
	if state == is_.STANDING or state == is_.CROUCHING:
		can_special_cancel = false
		can_auto_cancel = false
		can_normal_cancel = false

func _process(delta):
	change_facing_direction()
	facing_direction()
	counter_and_cancelling()
	if can_control == true:
		if cpu_level == 0:
			trigger_special_2()
			trigger_special_1()
			trigger_special_3(delta)
			trigger_special_4(delta)
			player_control(delta)
		else:
			cpu_control(delta)
	normal_cancels()
	repulse_players(delta)
	pushing_player(delta)
	stop_tweens_on_push()
	detect_stuck()
	concurrent_grab()
	lock_position()
	re_check_states()
	fall()
	boxes_auto_visibility()
	pass_info_to_hud()

	motion = position - last_position
	last_position = position
	
	camera_pos = camera.get_camera_screen_center()
	
	if state != is_.GRABBED and state != is_.LOCKED:
		self.position.x = clamp(self.position.x, camera_pos.x - 172, camera_pos.x + 172)
		self.position.y = clamp(self.position.y, stage_size.position.y, stage_size.end.y - 20)
	
	power_level = clamp(power_level, 0, 400)
	
	if proxboxes_detected > 0:
		can_guard = true
	else: can_guard = false

	$HUD/State.text = is_.keys()[state]

func _on_area_entered(area):
	if area.has_method("proximity_box"):
		proxboxes_detected += 1
	if area.has_method("repulse_players"):
		players_collide = true
		
func _on_area_exited(area):
	if area.has_method("proximity_box"):
		proxboxes_detected -= 1
	if area.has_method("_on_area_entered"):
		players_collide = false

func repulse_players(delta):
	if players_collide == true:
		if state != is_.ATTACKING_SP or state == is_.AIR_ATTACKING_SP:
			if must_face_right == true:
				self.position.x -= 200 * delta
			else: self.position.x += 200 * delta

func pushing_player(delta):
	if pushray.is_colliding() == true:
		if is_dashing_forward == true or is_jumping_forward == true or is_walking_forward == true:
			rival.position.x += self.motion.x
			if facing_right == true:
				rival.position.x = self.position.x + 45
			else: rival.position.x = self.position.x - 45

func stop_tweens_on_push():
	if pushray.is_colliding() == true:
		if is_dashing_forward == true and rival.is_dashing_forward == true or \
				is_dashing_forward == true and rival.is_stuck == true:
			tween.stop(self, "position:x")
		elif is_jumping_forward == true and rival.is_jumping_forward == true or \
				is_jumping_forward == true and rival.is_stuck == true:
			tween.stop(self, "position:x")
		elif state == is_.ATTACKING_SP or state == is_.AIR_ATTACKING_SP:
			tween.stop(self, "position:x")
	if pushray.is_colliding() == false:
		if state == is_.ATTACKING_SP or state == is_.AIR_ATTACKING_SP:
			tween.resume(self, "position:x")

func detect_stuck():
	if self.position.x < camera_pos.x - 192 + 25 or self.position.x > camera_pos.x + 192 - 25:
		is_stuck = true
	else: is_stuck = false

func _on_SpecialTimer1_timeout():
	sp1_input_count = 0
	
func _on_SpecialTimer2_timeout():
	sp2_input_count = 0
	
func _on_HitSpacerTimer_timeout():
	just_hitted = false
	
func _on_HurtBoxes_area_shape_entered(area_id, area, area_shape, self_shape):
	var collision_name = area.shape_owner_get_owner(shape_find_owner(area_shape))
	var area_name = collision_name.get_parent()
	var node_name = area_name.get_name()

	if just_hitted == false:
		just_hitted = true
		$HitSpacerTimer.start(0.001)
		if self_shape == 0:
			hitted_area = "Head"
		elif self_shape == 1 or self_shape == 3:
			hitted_area = "Torso"
		elif self_shape == 2:
			hitted_area = "Legs"
		
		if node_name == "HitBoxes":
			damaging_area = rival
			damaging_area.get_hitbox_rect()
			get_hurtbox_rectangle(self_shape)
			calculate_hitfx_drawing_area()
		else:
			damaging_area = rival.get_node(node_name)
			damaging_area.get_hitbox_rect()
			get_hurtbox_rectangle(self_shape)
			calculate_hitfx_drawing_area()
		if cpu_level != 0:
			cpu_block()
		on_hit()
	
func _on_GrabBox_area_entered(area):
	if state == is_.AIR_ATTACKING and (rival.state == is_.AIR_STUNNED \
			or rival.state == is_.JUMPING or rival.state == is_.AIR_ATTACKING):
		air_grab()
	else:
		rival.nearly_grabbed = true

func _on_GrabBox_area_exited(area):
	rival.nearly_grabbed = false

func _on_GrabCounterTimer_timeout():
	if rival.nearly_grabbed == true and state == is_.ATTACKING_ST:
		grab()
	else:
		yield($AnimationPlayer, "animation_finished")
		stand()
	
func get_hitbox_rect():
	var hit_area_center = $HitBoxes/HitBox1.position
	var hit_area_extents = $HitBoxes/HitBox1.shape.extents

	hit_area_pos = to_global(hit_area_center) - hit_area_extents
	hit_area_size = hit_area_extents * 2
		
	hit_area_rect = Rect2(hit_area_pos, hit_area_size) # Eliminar tras video
	
func get_hurtbox_rectangle(hurt_box):
	var hurt_area_center:= Vector2()
	var hurt_area_extents:= Vector2()
	
	if hurt_box == 0:
		hurt_area_center = $HurtBoxes/HurtBox1.position
		hurt_area_extents = $HurtBoxes/HurtBox1.shape.extents
	elif hurt_box == 1:
		hurt_area_center = $HurtBoxes/HurtBox2.position
		hurt_area_extents = $HurtBoxes/HurtBox2.shape.extents
	elif hurt_box == 2:
		hurt_area_center = $HurtBoxes/HurtBox3.position
		hurt_area_extents = $HurtBoxes/HurtBox3.shape.extents
	elif hurt_box == 3:
		hurt_area_center = $HurtBoxes/HurtBox4.position
		hurt_area_extents = $HurtBoxes/HurtBox4.shape.extents
	
	hurt_area_pos = to_global(hurt_area_center) - hurt_area_extents
	hurt_area_size = hurt_area_extents * 2
	hurt_area_rect = Rect2(hurt_area_pos, hurt_area_size) # Eliminar tras video
	
func calculate_hitfx_drawing_area():
	var hitfx_area_pos := Vector2()
	var hitfx_area_size := Vector2()
	var hitfx_area_end := Vector2()
	var rival_hit_area_pos = damaging_area.hit_area_pos
	var rival_hit_area_size = damaging_area.hit_area_size
	var rival_hit_area_end = damaging_area.hit_area_pos + damaging_area.hit_area_size
	var hurt_area_end = hurt_area_pos + hurt_area_size
	
	hitfx_area_pos.x = max(rival_hit_area_pos.x, hurt_area_pos.x)
	hitfx_area_pos.y = max(rival_hit_area_pos.y, hurt_area_pos.y)
	if rival_hit_area_end.x < hurt_area_end.x:
		hitfx_area_end.x = rival_hit_area_end.x
	else: hitfx_area_end.x = hurt_area_end.x
	if rival_hit_area_end.y < hurt_area_end.y:
		hitfx_area_end.y = rival_hit_area_end.y
	else: hitfx_area_end.y = hurt_area_end.y
	hitfx_area_size = hitfx_area_end - hitfx_area_pos
	hitfx_area_rect = Rect2(hitfx_area_pos, hitfx_area_size)
	
func calculate_damage(blocked):
	var raw_damage
	var scaled_damage
	
	if blocked == false:
		raw_damage = damaging_area.hit_damg
	else: raw_damage = damaging_area.hit_damg / 6
		
	if combo_counter <= 2:
		scaled_damage = raw_damage
	elif combo_counter == 3:
		scaled_damage = raw_damage * 80 / 100
	elif combo_counter == 4:
		scaled_damage = raw_damage * 70 / 100
	elif combo_counter == 5:
		scaled_damage = raw_damage * 60 / 100
	elif combo_counter == 6:
		scaled_damage = raw_damage * 50 / 100
	elif combo_counter == 7:
		scaled_damage = raw_damage * 40 / 100
	elif combo_counter == 8:
		scaled_damage = raw_damage * 30 / 100
	elif combo_counter == 9:
		scaled_damage = raw_damage * 20 / 100
	elif combo_counter >= 10:
		scaled_damage = raw_damage * 10 / 100
		
	health_level -= scaled_damage
	hud.substract_health(player, scaled_damage)
	
	if blocked == true:
		hud.combo_ended(player, combo_counter, health_level, true)
	if health_level <= 0:
		can_control = false
		rival.can_control = false
		Engine.time_scale = 0.5
		Engine.iterations_per_second = 30

func player_wins():
	var victory_animation = round(rand_range(0, 1))
	Engine.time_scale = 1
	Engine.iterations_per_second = 60
	if victory_animation == 0:
		$AnimationPlayer.play("Victory 1")
	else: $AnimationPlayer.play("Victory 2")
	yield(get_tree().create_timer(5), "timeout")
	get_parent().set_new_round()

func cpu_control(delta):
	if state == is_.STANDING or state == is_.CROUCHING:
		if cpu_move == do_.STAND:
			stand()
		if cpu_move == do_.CROUCH:
			crouch()
		if cpu_move == do_.WALK_F:
			walk_forward(delta)
		if cpu_move == do_.WALK_B:
			walk_backward(delta)
		if cpu_move == do_.JUMP_V or cpu_move == do_.JUMP_F or cpu_move == do_.JUMP_B:
			state = is_.PRE_JUMP
			$AnimationPlayer.play("Pre jump")
			yield($AnimationPlayer, "animation_finished")
			if cpu_move == do_.JUMP_V:
				yield(jump_vertical(), "completed")
			elif cpu_move == do_.JUMP_F:
				yield(jump_forward(), "completed")
			elif cpu_move == do_.JUMP_B:
				yield(jump_backward(), "completed")
			cpu_move = do_.STAND
		if cpu_move == do_.DASH_F or cpu_move == do_.DASH_B:
			if cpu_move == do_.DASH_F:
				yield(dash_forward(), "completed")
			if cpu_move == do_.DASH_B:
				yield(dash_backward(), "completed")
			cpu_move = do_.STAND

func cpu_movement():
	var main_action = rand_range(0, 10)
	var sub_action = rand_range(0, 10)
	var rival_distance = self.position.x - rival.position.x
	var border_distance
	
	if rival_distance < 0:
		rival_distance = -rival_distance
	if facing_right == true:
		border_distance = -((camera_pos.x - 172) - self.position.x)
	else: border_distance = (camera_pos.x + 172) - self.position.x
	
	print(rival_distance)
	if state == is_.STANDING or state == is_.CROUCHING:
		if rival_distance < 180:
			if main_action <= 1:
				cpu_move = do_.STAND
			elif main_action <= 2:
				cpu_move = do_.CROUCH
			elif main_action <= 4:
				if sub_action <= 6:
					cpu_move = do_.WALK_F
				else: cpu_move = do_.WALK_B
			elif main_action <= 6:
				if sub_action <= 6:
					cpu_move = do_.DASH_F
				else: cpu_move = do_.DASH_B
			elif main_action <= 7:
				if sub_action <= 3:
					cpu_move = do_.JUMP_F
				elif sub_action <= 7:
					cpu_move = do_.JUMP_V
				else: cpu_move = do_.JUMP_B
			elif main_action <= 8:
				special_3("Medium")
			elif main_action <= 9:
				special_4()
			elif main_action <= 10:
				if sub_action < 1:
					special_1("Light")
				elif sub_action < 4:
					special_1("Medium")
				elif sub_action < 7:
					special_1("Heavy")
				elif sub_action <= 10:
					if power_level >= 100:
						special_1("Powered")
					else: special_1("Heavy")
		elif rival_distance >= 180:
			if main_action <= 1:
				cpu_move = do_.STAND
			elif main_action <= 2:
				cpu_move = do_.CROUCH
			elif main_action <= 4:
				cpu_move = do_.WALK_F
			elif main_action <= 5:
				cpu_move = do_.DASH_F
			elif main_action <= 10:
				if sub_action <= 3:
					cpu_move = do_.JUMP_F
				else: cpu_move = do_.JUMP_V
			elif main_action <= 7:
				special_3("Heavy")
			elif main_action <= 10:
				if sub_action < 2:
					special_1("Light")
				elif sub_action < 5:
					special_1("Medium")
				elif sub_action < 8:
					special_1("Heavy")
				elif sub_action <= 10:
					if power_level >= 100:
						special_1("Powered")
					else: special_1("Heavy")
	$CPUMove.start(rand_range(0.5, 2))

func cpu_attack():
	var attack_action = rand_range(0, 10)
	var rival_distance = self.position.x - rival.position.x
	var reaction_time = -(cpu_level - 10) / 10.0
	
	if rival_distance < 0:
		rival_distance = -rival_distance
	if state == is_.STANDING or state == is_.CROUCHING:
		if rival_distance <= 90:
			if rival.state == is_.JUMPING or rival.state == is_.AIR_ATTACKING:
				if attack_action <= cpu_level:
					special_2("heavy")
			else:
				if rival_distance <= 50:
					if attack_action <= 4:
						standing_normal("LP")
					elif attack_action <= 8:
						crouching_normal("LK")
					else: grab_attempt()
				elif rival_distance <= 70:
					if attack_action <= 5:
						standing_normal("MP")
					else: standing_normal("MK")
				else:
					if attack_action <= 5:
						crouching_normal("MK")
					elif attack_action <= 10:
						standing_normal("HK")
	elif state == is_.JUMPING:
		if rival_distance <= 90:
			if attack_action <= 3:
				air_normal("LK")
			elif attack_action <= 6:
				air_normal("HP")
			else: air_normal("HK")

	$CPUAttack.start(rand_range(0, reaction_time))

func cpu_block():
	var block_probability = rand_range(0, 10)
	if block_probability < cpu_level:
		if state == is_.STANDING or state == is_.CROUCHING or state == is_.BLOCKING_H or \
				state == is_.BLOCKING_L or state == is_.BLOCK_STUNNED_H or \
				state == is_.BLOCK_STUNNED_L:
			if damaging_area.hit_area == "High":
				block_standing()
			elif damaging_area.hit_area == "Low":
				block_crouching()
			else:
				if block_probability < 0.5:
					block_standing()
				else: block_crouching()
	else: pass

func cpu_grab_escape():
	var escape_probability = rand_range(0, 10)
	
	if escape_probability <= cpu_level and state != is_.AIR_ATTACKING:
		grab_escape()
	else: pass

func _on_CPUMove_timeout():
	if can_control == true and cpu_level != 0:
		cpu_movement()

func _on_CPUAttack_timeout():
	if can_control == true and cpu_level != 0:
		cpu_attack()

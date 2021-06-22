extends Area2D

var speed = 0
var armor = 0
var px_owner
var hitted = false
var destroyed = false
var hit_area_pos:= Vector2()
var hit_area_size:= Vector2()
var hit_area_rect:= Rect2()

var hit_damg = 50 # Daño producido
var hit_stun = 50 # Aturdimiento producido
var hit_push = 15
var hit_strg # Light, Medium, Heavy, Launch, Sweep
var hit_area = "Mid" # High, Low or Mid (Si debe bloquearse alto, bajo o ambos valen)
var hit_type = "Special" # Normal < Special < Powered < Ultimate
var hit_jugg = true # Si es "true" puede golpearnos en estado "AIR_STUNNED"

func _ready():
	$AnimationPlayer.play("Normal")
	add_to_group("Projectiles")
	
func fireball_data(player_owner, facing_right, strenght):
	if player_owner == 1:
		px_owner = 1
		add_to_group("P1_projectiles")
		self.set_collision_layer(32)
		self.set_collision_mask(32768)
		$ProximityBox.set_collision_layer(8)
	else:
		px_owner = 2
		add_to_group("P2_projectiles")
		self.set_collision_layer(32768)
		self.set_collision_mask(32)
		$ProximityBox.set_collision_layer(8192)
	
	if strenght == "Heavy":
		hit_strg = "Heavy"
		speed = 200
	elif strenght == "Medium":
		hit_strg = "Heavy"
		speed = 140
	elif strenght == "Light":
		hit_strg = "Heavy"
		speed = 80
	else:
		hit_strg = "Heavy"
		hit_type = "Powered"
		hit_push = 30
		speed = 240
		armor = 1
		$Sprite.modulate = Color(1, 0.494118, 0.494118)
	if facing_right == false:
		speed = -speed
		scale.x = -scale.x
		
func _process(delta):
	if hitted == false and destroyed == false:
		position.x += speed * delta
	else: pass

func get_hitbox_rect():
	var hit_area_center = $HitBox.position
	var hit_area_extents = $HitBox.shape.extents

	hit_area_pos = to_global(hit_area_center) - hit_area_extents
	hit_area_size = hit_area_extents * 2
		
	hit_area_rect = Rect2(hit_area_pos, hit_area_size)

func disable_projectile():
	$HitBox.set_deferred("disabled", true)
	if armor > 0:
		armor -= 1
		$HitBox.set_deferred("disabled", false)
	else:
		destroyed = true
		remove_from_groups()
		$ProximityBox/ProxBox1.set_deferred("disabled", true)
		$AnimationPlayer.play("Impact")
		yield($AnimationPlayer, "animation_finished")
		self.visible = false
		yield(get_tree().create_timer(1, true), "timeout")
		queue_free()

func on_hit_freeze(freeze_time):
	hitted = true
	$AnimationPlayer.stop()
	yield(get_tree().create_timer(freeze_time, true), "timeout")
	hitted = false
	$AnimationPlayer.play()
	if armor == 0 and hit_type == "Powered":
		hit_strg = "Launch"
	if destroyed == false:
		$HitBox.set_deferred("disabled", false)
		
func remove_from_groups():
	if px_owner == 1:
		remove_from_group("P1_projectiles")
	else:
		remove_from_group("P2_projectiles")
	
func _on_FireBall_area_entered(area):
	if area.has_method("disable_projectile"):
		disable_projectile()
	else: pass
	
func _on_VisibilityNotifier2D_screen_exited():
	queue_free()

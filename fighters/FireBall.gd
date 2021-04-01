extends Area2D

var speed = 0
var hitted = false
var hit_area_pos:= Vector2()
var hit_area_size:= Vector2()
var hit_area_rect:= Rect2()

var hit_damg = 50 # Daño producido
var hit_stun = 50 # Aturdimiento producido
var hit_push = 30
var hit_strg = "Heavy" # Light, Medium, Heavy, Sweep
var hit_area = "Mid" # High, Low or Mid (Si debe bloquearse alto, bajo o ambos valen)
var hit_type = "Special" # Normal < Special < Powered < Ultimate
var hit_jugg = true # Si es "true" puede golpearnos en estado "AIR_STUNNED"

func _ready():
	$AnimationPlayer.play("Normal")
	
func fireball_data(player_owner, facing_right, strenght):
	if player_owner == 1:
		self.set_collision_layer(4)
		self.set_collision_mask(4096)
		$ProximityBox.set_collision_layer(8)
	else:
		self.set_collision_layer(4096)
		self.set_collision_mask(4)
		$ProximityBox.set_collision_layer(8192)
	
	if strenght == "heavy":
		speed = 200
	elif strenght == "medium":
		speed = 170
	elif strenght == "light":
		speed = 120
	if facing_right == false:
		speed = -speed
		scale.x = -scale.x
		
func _process(delta):
	if hitted == false:
		position.x += speed * delta
	else: pass

func get_hitbox_rect():
	var hit_area_center = $HitBox.position
	var hit_area_extents = $HitBox.shape.extents

	hit_area_pos = to_global(hit_area_center) - hit_area_extents
	hit_area_size = hit_area_extents * 2
		
	hit_area_rect = Rect2(hit_area_pos, hit_area_size)

func _on_FireBall_hits_rival(area):
	hitted = true
	$AnimationPlayer.play("Impact")
	yield($AnimationPlayer, "animation_finished")
	queue_free()

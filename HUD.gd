extends CanvasLayer

onready var tween = get_node("Tween")

var health_top_full = preload("res://gfx/hud/health_progress_full.png")
var health_top_damaged = preload("res://gfx/hud/health_progress.png")
var health_under_hit = preload("res://gfx/hud/health_under_hit.png")
var health_under_block = preload("res://gfx/hud/health_under_block.png")

func _ready():
	$P1Info.set_global_position(Vector2(20, 60))
	$P1Info.align = HALIGN_LEFT
	$P1Info.grow_horizontal = 1
	$P2Info.set_global_position(Vector2(324, 60))
	$P2Info.align = HALIGN_RIGHT
	$P2Info.grow_horizontal = 0
	
func initialize_health(player, health):
	if player == 1:
		$P1HealthMain.max_value = health
		$P1HealthMain.value = health
		$P1HealthSub.max_value = health
		$P1HealthSub.value = health
	else:
		$P2HealthMain.max_value = health
		$P2HealthMain.value = health
		$P2HealthSub.max_value = health
		$P2HealthSub.value = health

func substract_health(player, health):
	if player == 1:
		$P1HealthSub.texture_progress = health_under_hit
		$P1HealthMain.value -= health
		if $P1HealthMain.texture_progress == health_top_full:
			$P1HealthMain.texture_progress = health_top_damaged
	else:
		$P2HealthSub.texture_progress = health_under_hit
		$P2HealthMain.value -= health
		if $P2HealthMain.texture_progress == health_top_full:
			$P2HealthMain.texture_progress = health_top_damaged
#
func combo_ended(player, combo, health, blocked):
	if player == 1:
		if blocked == true:
			$P1HealthSub.texture_progress = health_under_block
		else: $P1HealthSub.texture_progress = health_under_hit
		if combo > 1:
			$P2InfoTimer.start(1)
			$P2Info.text = str(combo) + " HIT"
			$P2Info.show()
		tween.interpolate_property($P1HealthSub, "value", $P1HealthSub.value, health, 0.3, 
						Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
		tween.start()
		if $P2InfoTimer.is_stopped() == false:
			yield($P2InfoTimer, "timeout")
		$P2Info.hide()
	else:
		if blocked == true:
			$P2HealthSub.texture_progress = health_under_block
		else: $P2HealthSub.texture_progress = health_under_hit
		if combo > 1:
			$P1InfoTimer.start(1.5)
			$P1Info.text = str(combo) + " HIT"
			$P1Info.show()
		tween.interpolate_property($P2HealthSub, "value", $P2HealthSub.value, health, 0.3, 
						Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
		tween.start()
		if $P1InfoTimer.is_stopped() == false:
			yield($P1InfoTimer, "timeout")
		$P1Info.hide()

func manage_power(player, level):
	if player == 1:
		$P1PowerMeter/P1PowerLevel.value = level
	else:
		$P2PowerMeter/P2PowerLevel.value = level

func show_info(player, info):
	if player == 1:
		$P2InfoTimer.start(1)
		$P2Info.text = str(info)
		$P2Info.show()
		yield($P2InfoTimer, "timeout")
		$P2Info.hide()
	else:
		$P1InfoTimer.start(1)
		$P1Info.text = str(info)
		$P1Info.show()
		yield($P1InfoTimer, "timeout")
		$P1Info.hide()

func _process(delta):
	if $P1PowerMeter/P1PowerLevel.value >= 100:
		$P1PowerMeter/P1PowerLevel/P1PowerBar1.visible = true
	else: $P1PowerMeter/P1PowerLevel/P1PowerBar1.visible = false
	if $P1PowerMeter/P1PowerLevel.value >= 200:
		$P1PowerMeter/P1PowerLevel/P1PowerBar2.visible = true
	else: $P1PowerMeter/P1PowerLevel/P1PowerBar2.visible = false
	if $P1PowerMeter/P1PowerLevel.value >= 300:
		$P1PowerMeter/P1PowerLevel/P1PowerBar3.visible = true
	else: $P1PowerMeter/P1PowerLevel/P1PowerBar3.visible = false
	if $P1PowerMeter/P1PowerLevel.value>= 400:
		$P1PowerMeter/P1PowerLevel/P1PowerBar4.visible = true
	else: $P1PowerMeter/P1PowerLevel/P1PowerBar4.visible = false
	
	if $P2PowerMeter/P2PowerLevel.value >= 100:
		$P2PowerMeter/P2PowerLevel/P2PowerBar1.visible = true
	else: $P2PowerMeter/P2PowerLevel/P2PowerBar1.visible = false
	if $P2PowerMeter/P2PowerLevel.value >= 200:
		$P2PowerMeter/P2PowerLevel/P2PowerBar2.visible = true
	else: $P2PowerMeter/P2PowerLevel/P2PowerBar2.visible = false
	if $P2PowerMeter/P2PowerLevel.value >= 300:
		$P2PowerMeter/P2PowerLevel/P2PowerBar3.visible = true
	else: $P2PowerMeter/P2PowerLevel/P2PowerBar3.visible = false
	if $P2PowerMeter/P2PowerLevel.value>= 400:
		$P2PowerMeter/P2PowerLevel/P2PowerBar4.visible = true
	else: $P2PowerMeter/P2PowerLevel/P2PowerBar4.visible = false
		
		

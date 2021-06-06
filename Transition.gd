extends CanvasLayer

func _ready():
	pass

func fade_in(time):
	yield(get_tree().create_timer(0.2), "timeout")
	$Tween.interpolate_property($TransitionRect, "modulate", Color(0, 0, 0, 0), Color(0, 0, 0, 1), \
			time, Tween.TRANS_LINEAR, Tween.EASE_IN)
	$Tween.start()
	yield($Tween, "tween_completed")

func fade_out(time):
	yield(get_tree().create_timer(0.2), "timeout")
	$Tween.interpolate_property($TransitionRect, "modulate", Color(0, 0, 0, 1), Color(0, 0, 0, 0), \
			time, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	$Tween.start()
	yield($Tween, "tween_completed")

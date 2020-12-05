extends Area2D

func _ready():
	set_as_toplevel(true)
	set_global_position(Vector2(280, 150))

func _process(delta):
	if Input.is_action_just_pressed("TEST_PROX_BOX_AREA"):
		$TestProxBoxArea.disabled = not $TestProxBoxArea.disabled

func proximity_box():
	pass

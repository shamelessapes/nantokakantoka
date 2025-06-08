extends Camera2D

func _process(delta):
	if Global.shaking:
		position = Global.original_position + Vector2(
			randf_range(-Global.shake_intensity, Global.shake_intensity),
			randf_range(-Global.shake_intensity, Global.shake_intensity)
		)
	else:
		position = Global.original_position

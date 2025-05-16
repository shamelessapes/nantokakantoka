extends Node2D

func _ready():
	$particles.emitting = true  # 強制的に再生
	await get_tree().create_timer(1.0).timeout
	queue_free()

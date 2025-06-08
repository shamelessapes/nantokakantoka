extends Sprite2D

var rotation_speed = 90 # 1秒間に何度回すか（度数法）

func _process(delta):
	rotation_degrees += rotation_speed * delta  # 毎フレーム回転させる

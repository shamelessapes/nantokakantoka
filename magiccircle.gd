extends Sprite2D

var rotation_speed = 90 # 1秒間に何度回すか（度数法）

func ready():
	print("[Magiccircle] spawned at ", get_path())


func _process(delta):
	rotation_degrees += rotation_speed * delta  # 毎フレーム回転させる

extends Area2D

@export var speed := 1000  # 弾のスピード
@export var damage := 1    # 弾のダメージ（例: 1）
@onready var raycast = $RayCast2D

func _physics_process(delta):
	position.y -= speed * delta
	# RayCast2Dで先読み衝突判定
	if raycast.is_colliding():
		var collider = raycast.get_collider()
		if collider and collider.is_in_group("enemy"):
			if collider.has_method("take_damage"):
				collider.take_damage(damage)
			queue_free()

	# 画面外に出たら弾を消す
	if position.y < -1000:
		queue_free()

# 衝突時の処理
func _on_area_entered(area: Area2D) -> void:
	# 衝突した相手が敵かどうかをチェック
	var parent = area.get_parent()
	if parent.is_in_group("enemy") and parent.has_method("take_damage"):
		parent.take_damage(damage)
		queue_free()

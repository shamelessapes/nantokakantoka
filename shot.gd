extends Area2D

@export var speed := 1000  # 弾のスピード
@export var damage := 1    # 弾のダメージ（例: 1）

func _process(delta):
	# 上に進む（移動）
	position.y -= speed * delta

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

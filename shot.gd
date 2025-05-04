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
	if area.is_in_group("enemy"):  # 敵グループに所属していれば
		area.take_damage(damage)  # 敵にダメージを与える
		queue_free()  # 弾を消す

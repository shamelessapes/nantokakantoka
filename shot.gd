extends Area2D

@export var speed := 500  # 弾の移動速度
@export var base_damage := 2  # 弾の基本ダメージ
@onready var raycast = $RayCast2D

var has_hit := false  # 既にヒットしたかどうかのフラグ

# ダメージ倍率関連の定数（近いほど強く、遠いと弱く）
const MIN_MULTIPLIER = 0.9
const MAX_MULTIPLIER = 1.5
const CLOSE_DISTANCE = 80.0
const FAR_DISTANCE = 900.0

func _physics_process(delta):
	if has_hit:
		return  # 既に当たったら処理しない

	# 弾の移動処理
	position.y -= speed * delta
	raycast.target_position = Vector2(0, -speed * delta)
	raycast.force_raycast_update()

	# RayCastで敵に当たったか判定
	if raycast.is_colliding():
		var collider = raycast.get_collider()
		if collider and collider.is_in_group("enemy"):
			_process_hit(collider)
	
	# 画面外に出たら消える
	if position.y < -100:
		queue_free()

func _on_area_entered(area):
	if has_hit:
		return  # 既に当たったら無視
	if area.is_in_group("enemy"):
		
		_process_hit(area)

func _process_hit(enemy):
	if not enemy.has_method("take_damage"):
		return  # ダメージ処理できない場合は無視

	var players = get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return  # プレイヤーが見つからなければ無視

	var player_pos = players[0].global_position
	var enemy_pos = enemy.global_position
	var distance = player_pos.distance_to(enemy_pos)

	# 距離に応じた倍率計算
	var t = clamp((distance - CLOSE_DISTANCE) / (FAR_DISTANCE - CLOSE_DISTANCE), 0.0, 1.0)
	var multiplier = lerp(MAX_MULTIPLIER, MIN_MULTIPLIER, t)

	var final_damage = base_damage * multiplier
	enemy.take_damage(final_damage)

	has_hit = true
	queue_free()

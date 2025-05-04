extends Node2D

@export var enemy_scene: PackedScene  # 敵のシーン
@export var spawn_interval: float = 1.5  # 敵が出現する間隔（秒）
var spawn_timer: float = 0.0  # スポーンタイマー

@export var min_x: float = 100  # 出現させる最小X座標
@export var max_x: float = 800  # 出現させる最大X座標
@export var min_y: float = 100  # 出現させる最小Y座標
@export var max_y: float = 600  # 出現させる最大Y座標

func _ready():
	# 初期化処理
	pass

func _process(delta):
	# 敵を定期的に出現させる
	spawn_timer -= delta
	if spawn_timer <= 0.0:
		spawn_enemy()  # 敵を出現させる
		spawn_timer = spawn_interval  # タイマーをリセット

# 敵を制限された範囲で出現させる関数
func spawn_enemy():
	# ランダムな位置を設定（X軸とY軸両方に制限を追加）
	var spawn_position = Vector2(randf_range(min_x, max_x), randf_range(min_y, max_y))

	# 敵キャラクターをインスタンス化
	var enemy = enemy_scene.instantiate()

	# 敵の位置を設定
	enemy.position = spawn_position

	# ステージに追加
	get_parent().add_child(enemy)

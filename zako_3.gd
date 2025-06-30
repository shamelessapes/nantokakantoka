extends Area2D

@onready var explosion_scene = preload("res://tscn/explosion.tscn")  # 爆発エフェクトをロード
@onready var zakodead_sound: AudioStream = preload("res://se/se_damage9.mp3")  # 死亡時の音（音をファイルとしてロード）
const BULLET_SCN := preload("res://tscn/tekidan_4.tscn")
@export var speed: float = 150.0 # 移動速度
@export var direction: Vector2 = Vector2(1, 1).normalized() # 初期移動方向（右下）
@export var min_x: float = 280.0 # 折り返し左端X
@export var max_x: float = 710.0 # 折り返し右端X
@export var player_path: NodePath # プレイヤーノードパス（インスペクタで設定）
var hp := 35  # 敵の最大HP
var is_dead := false  # 死亡フラグ

@onready var zakodead_player = $AudioStreamPlayer  # AudioStreamPlayerノードを取得

var _fire_timer := 0.0 # 発射用タイマー
var _has_fired_once := false # 最初の1発を撃ったかどうか


func _ready():
	$AnimatedSprite2D.play("default")
	zakodead_player.stream = zakodead_sound

func _process(delta: float) -> void:
	position += direction * speed * delta

	# 左右の折り返し処理
	if position.x < min_x:
		position.x = min_x
		direction.x *= -1
	elif position.x > max_x:
		position.x = max_x
		direction.x *= -1

	# --- 弾発射処理 ---
	if position.y > 50 and not _has_fired_once:
		_fire_three_bullets()      # 一度目の発射
		_has_fired_once = true     # 一度発射したのでフラグ立てる
		_fire_timer = 0.0          # タイマー初期化（次の発射までカウント開始）

	elif _has_fired_once:
		_fire_timer += delta       # タイマー加算
		if _fire_timer >= 5.0:     # 3秒経ったら再発射
			_fire_three_bullets()
			_fire_timer = 0.0

	# 画面外に出たら削除
	if position.y > 1100:
		queue_free()


func _fire_three_bullets() -> void:
	var players = get_tree().get_nodes_in_group("player")
	SoundManager.play_se_by_path("res://se/se_beam05.mp3", 0)
	if players.is_empty():
		return
	var player = players[0] as Node2D

	var offsets := [Vector2(-20, 20), Vector2(0, 20), Vector2(20, 20)]
	for off in offsets:
		var bullet = BULLET_SCN.instantiate()
		bullet.global_position = global_position + off
		var dir: Vector2 = (player.global_position - bullet.global_position).normalized()
		if bullet is Tekidan4:
			bullet.direction = dir
		get_tree().current_scene.add_child(bullet)






func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("player"):
		area.take_damage()

func _on_shot_area_entered(area: Area2D) -> void:
	if area.is_in_group("player_shot"):
		var damage = area.damage
		take_damage(damage)

func take_damage(damage: int) -> void:
	if is_dead:
		return  # すでに死亡処理済みなら無視

	hp -= damage
	if hp <= 0:
		is_dead = true  # 死亡フラグを立てる
		SoundManager.play_se_by_path("res://se/Balloon-Pop01-1(Dry).mp3", +10)
		Global.add_score(10)
		explode()


func explode() -> void:
	var explosion = explosion_scene.instantiate()
	if get_parent():
		get_parent().add_child(explosion)
	else:
		get_tree().current_scene.add_child(explosion)
	explosion.global_position = global_position

	await get_tree().create_timer(0.05).timeout
	queue_free()

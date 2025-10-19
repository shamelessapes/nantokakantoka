extends Area2D

@onready var explosion_scene = preload("res://tscn/explosion.tscn")
const BULLET_SCN := preload("res://tscn/tekidan_4.tscn")

@export var speed: float = 200.0
var hp := 25
var is_dead := false
var is_invincible: bool = false
var is_blinking = false


func fire_bullet():
	var bullet = BULLET_SCN.instantiate()
	bullet.global_position = global_position
	get_tree().current_scene.add_child(bullet)

func _process(delta: float) -> void:
	$AnimatedSprite2D.play("default")
	# 画面外削除
	if position.y > 1100 or position.x < -100 or position.x > 1400:
		queue_free()

# --- 当たり判定＆死亡処理 ---
func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("player"):
		area.take_damage()

func _on_shot_area_entered(area: Area2D) -> void:
	if area.is_in_group("player_shot"):
		take_damage(area.damage)

# 無敵を一定時間だけ付与するメソッド
func be_invincible(duration: float) -> void:
	is_invincible = true
	print("無敵ON: " + str(duration) + "秒")

	var timer = Timer.new()
	timer.one_shot = true
	timer.wait_time = duration
	call_deferred("_add_and_start_timer", timer)  # ← ツリーに入るまで待つ

func _add_and_start_timer(timer: Timer) -> void:
	add_child(timer)
	timer.start()

	# タイマー終了時の処理
	timer.timeout.connect(func():
		if not is_instance_valid(self):
			return
		_end_invincibility()
		timer.queue_free()
	)
	
func _end_invincibility() -> void:
	if not is_invincible:
		return # ★ すでに無敵解除済みなら二度目以降は無視
	is_invincible = false
	print("無敵OFF")

func take_damage(damage: int) -> void:
	if is_dead or is_invincible:
		return
	if not is_blinking:
		is_blinking = true
		Global._do_blink_white($AnimatedSprite2D, self, 0.2, 1.0)

	hp -= damage
	if hp <= 0:
		is_dead = true
		explode()

func explode() -> void:
	var explosion = explosion_scene.instantiate()
	get_tree().current_scene.add_child(explosion)
	explosion.global_position = global_position
	SoundManager.play_se_by_path("res://se/Balloon-Pop01-1(Dry).mp3", +10)
	await get_tree().create_timer(0.05).timeout
	queue_free()

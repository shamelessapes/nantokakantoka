extends Area2D

@onready var explosion_scene = preload("res://tscn/explosion.tscn")
#@onready var zakodead_sound: AudioStream = preload("res://se/se_damage9.mp3")
const BULLET_SCN := preload("res://tscn/tekidan_4.tscn")

@export var speed: float = 200.0
@export var player_path: NodePath
var direction: Vector2 = Vector2.ZERO
var hp := 40
var is_dead := false
var is_invincible: bool = false
var verocity := Vector2.ZERO   #速度ベクトル

#@onready var zakodead_player = $AudioStreamPlayer
var is_blinking = false


# --- ✅ ステージ管理から呼ばれる移動開始関数 ---
func move_to(dir: Vector2):
	direction = dir.normalized()

# --- ✅ ステージ管理から呼ばれる発射関数 ---
func fire_bullet():
	var bullet = BULLET_SCN.instantiate()
	bullet.global_position = global_position
	get_tree().current_scene.add_child(bullet)

func _process(delta: float) -> void:
	if direction != Vector2.ZERO:
		position += direction * speed * delta
	
	# 画面外削除
	if position.y > 1100:
		queue_free()
	
	if verocity.x < 0:  # 左に動いている場合
		$AnimatedSprite2D.play("left")
	elif verocity.x > 0:  # 右に動いている場合
		$AnimatedSprite2D.play("right")
	else:  # どちらにも動いていない場合
		$AnimatedSprite2D.play("right")

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
	_end_invincibility()
	
func _end_invincibility() -> void:
	if not is_invincible:
		return # ★ すでに無敵解除済みなら二度目以降は無視
	is_invincible = false
	print("無敵OFF")

func take_damage(damage: int) -> void:
	if is_dead: return
	if is_invincible:
		print("無敵中")
		return
	if not is_blinking:
		is_blinking = true
		Global._do_blink_white($AnimatedSprite2D, self, 0.2,1.0)

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

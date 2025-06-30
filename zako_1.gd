extends Area2D

@export var speed := 300  # 敵の移動速度（下方向）
@onready var explosion_scene = preload("res://tscn/explosion.tscn")  # 爆発エフェクトをロード
@onready var zakodead_sound: AudioStream = preload("res://se/se_damage9.mp3")  # 死亡時の音（音をファイルとしてロード）

var hp := 1  # 敵の最大HP
var is_dead := false  # 死亡フラグ

@onready var zakodead_player = $AudioStreamPlayer  # AudioStreamPlayerノードを取得

var is_invincible: bool = false

func _on_invincibility_end():
	is_invincible = false


func _ready():
	$animationsprite2D.play("zako1")
	zakodead_player.stream = zakodead_sound

var can_move := true  # ← これを追加

func _process(delta):
	if can_move:
		position.y += speed * delta
	if position.y > 1000:
		queue_free()
		
func _resume_move():
	can_move = true
		
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
		#play_death_sound()
		Global.add_score(10)
		explode()

#func play_death_sound() -> void:
	#var new_sound = AudioStreamPlayer2D.new()
	#new_sound.stream = zakodead_sound
	#new_sound.volume_db = 0
	#new_sound.position = position  # global_position は使わない (Godot 4.2以降では position でOK)
	#get_tree().current_scene.add_child(new_sound)
	#new_sound.play()

	#new_sound.finished.connect(func(): new_sound.queue_free())

func explode() -> void:
	var explosion = explosion_scene.instantiate()
	if get_parent():
		get_parent().add_child(explosion)
	else:
		get_tree().current_scene.add_child(explosion)
	explosion.global_position = global_position

	await get_tree().create_timer(0.05).timeout
	queue_free()

extends Node

# Singleton（AutoLoad）で使うことを想定

var is_hitstop = false

# 弾消去エフェクト
@onready var bullet_erase_scene = preload("res://tscn/bullet_erase.tscn")

# 弾消去＋エフェクト表示＋SE再生
func bullet_erase(position: Vector2):
	if bullet_erase_scene:
		var effect = bullet_erase_scene.instantiate()
		effect.position = position
		get_tree().current_scene.add_child(effect)


# 汎用エフェクト・SE（例：ボス出現時など）
func play_effect_and_sound(position: Vector2) -> void:
	var effect = preload("res://tscn/accumulate_power.tscn").instantiate()
	effect.global_position = position
	get_tree().root.add_child(effect)

	var player = effect.get_node("AudioStreamPlayer2D")
	player.play()
	
func apply_hitstop(duration := 0.1):
	is_hitstop = true
	await get_tree().create_timer(duration).timeout
	is_hitstop = false

# TODO: 必要に応じてここに追加のグローバル関数・変数を定義

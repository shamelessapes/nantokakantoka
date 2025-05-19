extends Node

# Singleton（AutoLoad）で使うことを想定
var boss_dead_effect_scene = preload("res://tscn/boss_dying.tscn") 
var is_hitstop = false

func _ready():
	print("✅ Global.gd ready!", boss_dead_effect_scene)


func play_boss_dead_effect(position: Vector2):
	if boss_dead_effect_scene:
		print("💥 爆発エフェクトを生成しに行きます at", position)
		var effect = boss_dead_effect_scene.instantiate()
		effect.global_position = position
		get_tree().root.add_child(effect)  # ← global_position を使うなら root に！
		print("✅ 爆発エフェクト生成 & 追加完了 at", position)
	else:
		print("❌ boss_dead_effect_scene が null！")

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

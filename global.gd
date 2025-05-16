extends Node2D

var charge_anim_scene := preload("res://tscn/accumulate_power.tscn")
var bullet_pop := preload("res://tscn/bullet_erase.tscn")
var is_hitstop := false


func play_effect_and_sound(position: Vector2) -> void:
	var effect = preload("res://tscn/accumulate_power.tscn").instantiate()
	effect.global_position = position
	get_tree().root.add_child(effect)

	var player = effect.get_node("AudioStreamPlayer2D")
	player.play()
	
func bullet_erase(position: Vector2) -> void:
	var bullet_pop_effect = preload("res://tscn/bullet_erase.tscn").instantiate()
	bullet_pop_effect.global_position = position
	get_tree().root.add_child(bullet_pop_effect)
	
func apply_hitstop(duration := 0.1):
	is_hitstop = true
	await get_tree().create_timer(duration).timeout
	is_hitstop = false

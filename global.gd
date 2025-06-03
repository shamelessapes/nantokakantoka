extends Node

var boss_dead_effect_scene = preload("res://tscn/boss_dying.tscn") 
var is_hitstop = false
var shake_intensity: float = 0.0
var camera_node: Camera2D  # 揺らすカメラを登録する用の変数
var shake_timer: Timer  # タイマーを保存する変数
var shaking: bool = false  # 揺れ中かどうかを判定するフラグ
var original_position: Vector2  # 元の位置を保存する変数
var score = 0  # スコアを保持する変数

signal score_changed(new_score)

#func _ready():
	#print("✅ Global.gd ready!", boss_dead_effect_scene)

# スコアを加算する関数
func add_score(points: int) -> void:
	score += points
	emit_signal("score_changed", score)  # スコア変化を通知
	print("スコア更新:", score)

func reset_score() -> void:
	score = 0
	emit_signal("score_changed", score)
	print("スコアをリセットしました")
	
func add_time_bonus_score(time_remaining: float):
	var bonus = int(time_remaining * 100)  # 例：1秒ごとに100点
	score += bonus
	emit_signal("score_changed", score)


func set_pause_mode_for_scene(root_node: Node):
	# ゲーム中のノードを一括でPAUSABLEにする例
	for node in root_node.get_children():
		if node.is_in_group("pausable"):
			node.pause_mode = Node.PROCESS_MODE_PAUSABLE
		elif node.is_in_group("UI"):
			node.pause_mode = Node.PROCESS_MODE_ALWAYS


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

# カメラを登録する
func register_camera(cam: Camera2D) -> void:
	camera_node = cam
	original_position = camera_node.position

# 揺れを開始する
func shake_screen(intensity: float = 5.0, duration: float = 0.5) -> void:
	if camera_node == null:
		push_error("カメラが登録されてないよ！")
		return

	shake_intensity = intensity
	shaking = true

	# タイマー作成
	shake_timer = Timer.new()
	shake_timer.wait_time = duration
	shake_timer.one_shot = true
	add_child(shake_timer)

	shake_timer.timeout.connect(_on_shake_timeout)
	shake_timer.start()

# 揺れ終了処理
func _on_shake_timeout() -> void:
	shaking = false
	if shake_timer:
		shake_timer.queue_free()
	if camera_node:
		camera_node.position = original_position

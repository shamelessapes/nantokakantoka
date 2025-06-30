extends Node

var boss_dead_effect_scene = preload("res://tscn/boss_dying.tscn") 
var is_hitstop = false
var shake_intensity: float = 0.0
var camera_node: Camera2D  # 揺らすカメラを登録する用の変数
var shake_timer: Timer  # タイマーを保存する変数
var shaking: bool = false  # 揺れ中かどうかを判定するフラグ
var original_position: Vector2  # 元の位置を保存する変数
var score = 0  # スコアを保持する変数
var is_talking := false

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

var saved_lives: int = -1  # -1 なら未保存（初期化判定に使う）

# HPを保存する
func save_current_lives(lives: int):
	saved_lives = lives
	print("💾 HP保存: ", lives)

# プレイヤーにHPを読み込ませる
func load_current_lives(player):
	if saved_lives != -1:
		player.current_lives = saved_lives
		print("📤 HP復元: ", saved_lives)
	else:
		print("📤 HP復元なし（初期値使用）")


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


# --- フェード用変数
var fade_layer := CanvasLayer.new()
var color_rect := ColorRect.new()

func _ready():
	# フェード用ノードの構築
	fade_layer.layer = 100  # レイヤー順（UIより上に）
	add_child(fade_layer)

	color_rect.name = "FadeOverlay"
	color_rect.color = Color.WHITE
	color_rect.anchor_left = 0.0
	color_rect.anchor_top = 0.0
	color_rect.anchor_right = 1.0
	color_rect.anchor_bottom = 1.0
	color_rect.modulate.a = 0.0  # 最初は透明
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE  # マウスイベント無視（クリック透過）
	color_rect.z_index = 1  # UIより前面に来るようにする（念のため）
	color_rect.z_as_relative = false  # グローバルなz_indexとして扱う
	color_rect.size_flags_horizontal = Control.SIZE_FILL
	color_rect.size_flags_vertical = Control.SIZE_FILL
	color_rect.size = get_viewport().get_visible_rect().size

	fade_layer.add_child(color_rect)

	call_deferred("_resize_color_rect")

func _resize_color_rect():
	await get_tree().process_frame
	color_rect.size = get_viewport().get_visible_rect().size

# --- フェードアウトしてシーン遷移
func change_scene_with_fade(path: String, color: Color = Color.BLACK, duration: float = 1.5) -> void:
	color.a = 0.0  # 最初は透明から始める
	color_rect.modulate = color
	color_rect.show()
	var tween = create_tween()
	tween.tween_property(color_rect, "modulate:a", 1.0, duration) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await tween.finished
	get_tree().change_scene_to_file(path)


# --- フェードイン（画面表示開始時用）
func fade_in(color: Color = Color.WHITE, _duration: float = 1.0) -> void:
	color.a = 1.0
	color_rect.modulate = color
	color_rect.show()
	var tween = create_tween()
	tween.tween_property(color_rect, "modulate:a", 0.0, _duration) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await tween.finished
	color_rect.hide()

# --- フェードアウト（画面を暗くする）
func fade_out(color: Color = Color.BLACK, _duration: float = 1.0) -> void:
	color.a = 0.0  # 最初は透明な状態で開始
	color_rect.modulate = color
	color_rect.show()
	var tween = create_tween()
	tween.tween_property(color_rect, "modulate:a", 1.0, _duration) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await tween.finished
	# フェードアウト後はあえて表示を残す（シーン遷移などの直前用）

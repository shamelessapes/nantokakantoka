extends Control


var player  # プレイヤーを格納する変数

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	# ボタンの接続
	$do_continue.pressed.connect(on_yes_pressed)
	$giveup.pressed.connect(on_no_pressed)
	
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]
	else:
		print("⚠️ player グループに属するノードが見つからなかったよ！")

	# 最初は非表示
	hide()
	process_mode = Node.PROCESS_MODE_ALWAYS  # ポーズ中でも動かす

func on_yes_pressed():
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		var player = players[0]
		print("コンティニューするよ！")
		SoundManager.play_se_by_path("res://se/決定ボタンを押す49.mp3")
		Global.reset_score()
		get_tree().paused = false
		await get_tree().create_timer(0.1).timeout  # 少し待つ
		player.current_lives += 3
		player.emit_signal("life_changed", player.current_lives)
		Global.save_current_lives(player.current_lives)  # ← 修正ここ！
		player.show()
		player.start_blink()
		player.invincible = true
		_disable_invincible_later(player)
	else:
		print("⚠️ player グループに属するノードが見つからないよ！")

	queue_free()

func _disable_invincible_later(player):
	await get_tree().create_timer(3.0).timeout
	player.invincible = false



func on_no_pressed():
	# タイトル画面に戻る
	print("タイトルに戻るよ！")
	SoundManager.play_se_by_path("res://se/決定ボタンを押す49.mp3")
	get_tree().paused = false
	await Global.change_scene_with_fade("res://tscn/title_demo.tscn",Color.BLACK)
	queue_free()

extends Node2D

const START_LIVES: int = 3                     # このステージの初期ライフ

var is_hitstop: bool = false

func _enter_tree() -> void:
	# ★ 子（プレイヤー）が _ready() で Global を読む前に、まず初期値を入れておく
	Global.reset_score()                        # スコアもリセット
	Global.save_current_lives(START_LIVES)      # グローバルの現在ライフを3に上書き

func _ready() -> void:
	# ここに来るころにはプレイヤーがシーンに入っているはずだが、
	# 念のため1フレーム待ってからUIの見た目を整える
	await get_tree().process_frame

	# グループ "player" からプレイヤーを取得（存在しない場合はスキップ）
	var players: Array = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		var player = players[0]
		# プレイヤー本体の値も明示的に初期化（保険）
		player.current_lives = START_LIVES
		player.update_life_ui(START_LIVES)      # ライフ表示を更新

	$AudioStreamPlayer2D.play()

func _physics_process(delta: float) -> void:
	if Global.is_hitstop:
		return  # ヒットストップ中はスクロール停止

	# 背景画像スクロール
	$bg/Parallax2D.scroll_offset.y += 25
	$bg/Parallax2D2.scroll_offset.y += 12
	$bg/Parallax2D3.scroll_offset.y += 2

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		toggle_pause()

func toggle_pause() -> void:
	if get_tree().paused:
		get_tree().paused = false
		$PauseMenu.visible = false
	else:
		get_tree().paused = true
		$PauseMenu.visible = true
		$PauseMenu/Restart.grab_focus()
		SoundManager.play_se_by_path("res://se/決定ボタンを押す49.mp3")

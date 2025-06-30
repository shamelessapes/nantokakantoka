extends Node2D

var is_hitstop := false

func _physics_process(delta: float) -> void:
	if Global.is_hitstop:
		return  # ヒットストップ中はスクロール停止！

	# 背景画像スクロール
	$bg/Parallax2D.scroll_offset.y += 25
	$bg/Parallax2D2.scroll_offset.y += 12
	$bg/Parallax2D3.scroll_offset.y += 2
	
func _ready():
	$AudioStreamPlayer2D.play()

func _unhandled_input(event):
	if event.is_action_pressed("pause"):
		toggle_pause()

func toggle_pause():
	if get_tree().paused:
		get_tree().paused = false
		$PauseMenu.visible = false  # PauseMenuノードを非表示

	else:
		get_tree().paused = true
		$PauseMenu.visible = true   # PauseMenuノードを表示
		SoundManager.play_se_by_path("res://se/決定ボタンを押す49.mp3")

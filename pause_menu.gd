extends Control

func _ready():
	# 最初は非表示
	hide()
	process_mode = Node.PROCESS_MODE_ALWAYS  # ポーズ中でも動かす

	$Restart.pressed.connect(on_exit_pressed)
	$ReturntoTitle.pressed.connect(on_resume_pressed)
	$ColorRect.color = Color(0, 0, 0, 0.5)  # 半透明黒
	$ColorRect.size = Vector2(1280, 960)
	$ColorRect.modulate = Color(0, 0, 0, 1)
	$ColorRect.z_index = -10
	$Restart.grab_focus()

func on_exit_pressed():
	get_tree().paused = false
	hide()

func on_resume_pressed():
	get_tree().paused = false
	hide()
	await Global.change_scene_with_fade("res://tscn/title_demo.tscn" , Color.BLACK)

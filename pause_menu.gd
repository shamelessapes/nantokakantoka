extends Control

func _ready():
	# 最初は非表示
	hide()
	process_mode = Node.PROCESS_MODE_ALWAYS  # ポーズ中でも動かす

	$Restart.pressed.connect(on_exit_pressed)
	$ReturntoTitle.pressed.connect(on_resume_pressed)

func on_exit_pressed():
	get_tree().paused = false
	hide()

func on_resume_pressed():
	get_tree().paused = false
	hide()

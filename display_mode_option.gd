extends OptionButton  # ←ここをButtonじゃなくてOptionButtonにする！

func _ready():
	# 選択肢を追加（インデックス順に注意！）
	add_item("ウィンドウモード")  # index 0
	add_item("フルスクリーン")    # index 1

	item_selected.connect(_on_display_mode_selected)

func _on_display_mode_selected(index: int) -> void:
	match index:
		0:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		1:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

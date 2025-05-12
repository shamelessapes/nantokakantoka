extends CanvasLayer

func update_life_ui(lives: int):
	for i in range(5):
		var heart = get_node("HBoxContainer/heart" + str(i + 1))  # get_nodeを使用
		heart.visible = i < lives

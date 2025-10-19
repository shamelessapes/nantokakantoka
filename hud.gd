extends CanvasLayer

@onready var score_label = $ScoreLabel

func _ready():
	# Globalのスコア変化シグナルに接続
	Global.connect("score_changed", Callable(self, "_on_score_changed"))
	# 最初に現在のスコアを表示しておく
	_on_score_changed(Global.score)

func update_life_ui(lives: int):
	print("ハート更新中！ライフ数: ", lives)
	for i in range(5):
		var heart = get_node("HBoxContainer/heart" + str(i + 1))  # get_nodeを使用
		heart.visible = i < lives



func _on_score_changed(new_score):
	score_label.text = str(new_score)

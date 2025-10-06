extends CanvasLayer

@onready var left_character := $akane         # 明音
@onready var right_character_1 := $sakura    # 桜
@onready var right_character_2 := $ponsuke_img    
@onready var name_label := $Namelabel
@onready var message_label := $dialogue
@onready var message_panel := $hukidasi         # 吹き出し背景
@onready var animeplayer := $Anime_ponsuke_name
@onready var boss_node = get_node("../ponsuke")  # パスは正確に書いてね！
signal dialogue_finished

var dialogue = []  # 現在の会話セット
var dialogue_index := 0
var appeared_characters := []
var is_after_battle := false  # 戦闘後会話ならtrueにする


# 会話データ（画像ファイル名をそのまま使う形）
var dialogue_beforebattle = [
	{ "speaker": "sakura", "expression": "sakuraface (1)", "bubble": "hukidasi (1)", "text": "今は戦闘前よ" },
]

var dialogue_afterbattle = [
	{ "speaker": "sakura", "expression": "sakuraface (1)", "bubble": "hukidasi (1)", "text": "戦闘後よ" },
]

func _ready():
	hide()
	Global.is_talking = false
	var stage = get_parent().get_node("stagemanager_2")  # 親から子を探す
	stage.connect("stage_cleared", Callable(self, "_on_stage_cleared"))
	
	
func _on_stage_cleared():
	show()
	start_dialogue(false)  # ステージ開始時はバトル前会話を開始


func _on_battle_ended():
	start_dialogue(true)

func start_dialogue(after_battle: bool):
	is_after_battle = after_battle
	dialogue_index = 0
	#appeared_characters.clear()
	self.visible = true
	Global.is_talking = true
	dialogue = dialogue_afterbattle if after_battle else dialogue_beforebattle
	show_next_line()

func _unhandled_input(event):
	if event.is_action_pressed("ui_accept"):
		show_next_line()

func show_next_line():
	if dialogue_index >= dialogue.size():
		hide_dialogue()
		return
		
	if not is_after_battle:
		if dialogue_index == 1:
			boss_node.visible = true
			emit_signal("dialogue_finished")
			boss_node.set_boss_battle_gate(true)
		if dialogue_index == 0 and not is_after_battle:
			if boss_node:
				boss_node.show()      # まず見えるようにする
				boss_node._boss_show() # 非同期は気にせず呼ぶ
		if dialogue_index == 14:
			name_label.text = "ぽん助"
			animeplayer.play("karakasa_name")

	var line = dialogue[dialogue_index]
	dialogue_index += 1

	var speaker = line["speaker"]
	var expression = line["expression"]
	var bubble_file = line["bubble"]
	var text = line["text"]

	# 表情切り替え
	match speaker:
		"akane":
			set_expression(left_character, "akane", expression)
			set_character_active(left_character, true)
			set_character_active(right_character_1, false)
			set_character_active(right_character_2, false)
			left_character.z_index = 1
			right_character_1.z_index = 0
		"sakura":
			set_expression(right_character_1, "sakura", expression)
			set_character_active(left_character, false)
			set_character_active(right_character_1, true)
			set_character_active(right_character_2, false)
			right_character_1.z_index = 1
			left_character.z_index = 0
		"ponsuke":
			set_expression(right_character_2, "ponsuke", expression)
			set_character_active(left_character, false)
			set_character_active(right_character_1, false)
			set_character_active(right_character_2, true)

	# 対象のノードを取得
	var character_node: TextureRect
	if speaker == "sakura":
		character_node = right_character_1
	elif speaker == "akane":
		character_node = left_character
	elif speaker == "ponsuke":
		character_node = right_character_2
	else:
		character_node = null
	
	# 表情画像の設定
	if character_node:
		character_node.texture = load("res://image/character/%s/%s.png" % [speaker, expression])
		
		# 初登場かチェックしてTween演出
		if not appeared_characters.has(speaker):
			appeared_characters.append(speaker)
			# 初期位置をちょっと下にする（画面下にずらす）
			var original_pos = character_node.position
			character_node.position.y += 100
			var tween = create_tween()
			tween.tween_property(character_node, "position", original_pos, 0.4)\
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	# 吹き出しの切り替え
	update_bubble(bubble_file)

	message_label.text = text

func set_expression(character_node: TextureRect, char_id: String, expression_file: String):
	var path = "res://image/character/%s/%s.png" % [char_id, expression_file]
	character_node.texture = load(path)

func update_bubble(bubble_file: String):
	var path = "res://image/character/hukidasi/%s.png" % bubble_file
	message_panel.texture = load(path)

func set_character_active(character_node: TextureRect, active: bool):
	character_node.modulate = Color(1, 1, 1, 1) if active else Color(0.5, 0.5, 0.5, 1)

func hide_dialogue():
	self.visible = false
	Global.is_talking = false
	# dialogue_finished をボスの関数に渡す
	emit_signal("dialogue_finished")

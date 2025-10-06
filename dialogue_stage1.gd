extends CanvasLayer

@onready var left_character := $akane         # 明音
@onready var right_character_1 := $sakura    # 桜
@onready var right_character_2 := $karakasaobake    # 唐傘
@onready var name_label := $Namelabel
@onready var message_label := $dialogue
@onready var message_panel := $hukidasi         # 吹き出し背景
@onready var animeplayer := $Anime_karakasa_name 
@onready var boss_node = get_node("../boss1")  # パスは正確に書いてね！
signal dialogue_finished

var dialogue = []  # 現在の会話セット
var dialogue_index := 0
var appeared_characters := []
var is_after_battle := false  # 戦闘後会話ならtrueにする


# 会話データ（画像ファイル名をそのまま使う形）
var dialogue_beforebattle = [
	{ "speaker": "sakura", "expression": "sakuraface (1)", "bubble": "hukidasi (1)", "text": "……やっぱり変だわ。" },
	{ "speaker": "sakura", "expression": "sakuraface (2)", "bubble": "hukidasi (1)", "text": "白昼堂々、町中にこんなに妖怪がうじゃうじゃいるなんて！" },
	{ "speaker": "akane",  "expression": "akane (1)",  "bubble": "hukidasi (1)", "text": "それなー？" },
	{ "speaker": "akane",  "expression": "akane (2)",  "bubble": "hukidasi (1)", "text": "しかもコイツらいつもよりタフだおね。" },
	{ "speaker": "sakura", "expression": "sakuraface (3)", "bubble": "hukidasi (1)", "text": "ね……ったく、鬱陶しいことこの上無いわ！" },
	{ "speaker": "null", "expression": "null", "bubble": "hukidasi (4)", "text": "おっ！" },
	{ "speaker": "karakasa", "expression": "karakasaobake (1)", "bubble": "hukidasi (4)", "text": "妖怪からも人間からも仲間はずれの半妖じゃねーか！" },
	{ "speaker": "karakasa", "expression": "karakasaobake (2)", "bubble": "hukidasi (4)", "text": "今日もみじめにお散歩でちゅか～？" },
	{ "speaker": "karakasa", "expression": "karakasaobake (3)", "bubble": "hukidasi (3)", "text": "ぎゃはははははは！かわいそ〜" },
	{ "speaker": "sakura", "expression": "sakuraface (4)", "bubble": "hukidasi (1)", "text": "……うわでた。" },
	{ "speaker": "akane",  "expression": "akane (3)",  "bubble": "hukidasi (1)", "text": "あ、コイツって確か昔\n桜のこといじめてた妖怪だおね？" },
	{ "speaker": "akane",  "expression": "akane (5)",  "bubble": "hukidasi (1)", "text": "確か名前は、唐傘おばけ…だっけ。" },
	{ "speaker": "sakura", "expression": "sakuraface (5)", "bubble": "hukidasi (1)", "text": "そうよ、まあその度に私がボコボコにしてやったけどね。" },
	{ "speaker": "akane",  "expression": "akane (4)",  "bubble": "hukidasi (1)", "text": "コイツも懲りないおね〜。" },
	{ "speaker": "karakasa", "expression": "karakasaobake (2)", "bubble": "hukidasi (4)", "text": "へへ……なんだか今日は力が溢れてたまらねぇぜ。" },
	{ "speaker": "karakasa", "expression": "karakasaobake (3)", "bubble": "hukidasi (3)", "text": "ちょうどいい！半妖、お前で力試ししてやる！" },
]

var dialogue_afterbattle = [
	{ "speaker": "karakasa", "expression": "karakasaobake (5)", "bubble": "hukidasi (4)", "text": "ちょ、ちょうしにのってしゅみましぇんでした……。" },
	{ "speaker": "sakura", "expression": "sakuraface (6)", "bubble": "hukidasi (1)", "text": "これに懲りたらもうちょっかい出さないでよね。" },
	{ "speaker": "sakura", "expression": "sakuraface (7)", "bubble": "hukidasi (1)", "text": "……ま、アンタは懲りないんでしょうけど。" },
	{ "speaker": "akane", "expression": "akane (5)", "bubble": "hukidasi (1)", "text": "てかさー、こいつもバカだおね。\n桜がひとりぼっちなんて。" },
	{ "speaker": "akane", "expression": "akane (6)", "bubble": "hukidasi (1)", "text": "桜には明音がいるのに。" },
	{ "speaker": "sakura", "expression": "sakuraface (8)", "bubble": "hukidasi (1)", "text": "あはは、確かにそうじゃん。" },
	{ "speaker": "sakura", "expression": "sakuraface (9)", "bubble": "hukidasi (1)", "text": "……さてと、先に進むとしますか。" },
]

func _ready():
	Global.is_talking = true
	boss_node.connect("battle_ended", Callable(self, "_on_battle_ended"))
	start_dialogue(false)

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
		if dialogue_index == 6 and boss_node:
			boss_node.visible = true
			boss_node.start_entrance_animation()
		if dialogue_index == 14:
			name_label.text = "唐傘おばけ"
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
		"karakasa":
			set_expression(right_character_2, "karakasa", expression)
			set_character_active(left_character, false)
			set_character_active(right_character_1, false)
			set_character_active(right_character_2, true)

	# 対象のノードを取得
	var character_node: TextureRect
	if speaker == "sakura":
		character_node = right_character_1
	elif speaker == "akane":
		character_node = left_character
	elif speaker == "karakasa":
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
	emit_signal("dialogue_finished")  # 会話終わったよ！

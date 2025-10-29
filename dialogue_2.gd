extends CanvasLayer

@onready var left_character := $akane         # 明音
@onready var right_character_1 := $sakura    # 桜
@onready var right_character_2 := $ponsuke_img    
@onready var name_label := $Namelabel
@onready var message_label := $dialogue
@onready var message_panel := $hukidasi         # 吹き出し背景
@onready var animeplayer := $Anime_ponsuke_name
@onready var boss_node = get_node("../ponsuke")  
signal dialogue_finished

var dialogue = []  # 現在の会話セット
var dialogue_index := 0
var appeared_characters := []
var is_after_battle := false  # 戦闘後会話ならtrueにする


# 会話データ（画像ファイル名をそのまま使う形）
var dialogue_beforebattle = [
	{ "speaker": "sakura", "expression": "surprise", "bubble": "hukidasi (1)", "text": "よし、じゃあここら辺に盛り塩置くわよ。" },
	{ "speaker": "akane", "expression": "surprise", "bubble": "hukidasi (1)", "text": "待って桜、前方から何か来る！" },
	{ "speaker": "ponsuke", "expression": "aseri", "bubble": "hukidasi (3)", "text": "わあああ、親分！\nた、助けてください！" },
	{ "speaker": "sakura", "expression": "smile", "bubble": "hukidasi (1)", "text": "あれ、ぽん助じゃん。\n久しぶり。" },
	{ "speaker": "akane", "expression": "surprise", "bubble": "hukidasi (1)", "text": "え、この妖怪と知り合いなのかお？" },
	{ "speaker": "sakura", "expression": "normal", "bubble": "hukidasi (1)", "text": "うん、こいつはぽん助。\n私の子分よ。" },
	{ "speaker": "sakura", "expression": "niko", "bubble": "hukidasi (1)", "text": "まあ子分兼家族ってとこかな。" },
	{ "speaker": "sakura", "expression": "niko", "bubble": "hukidasi (1)", "text": "ほら、私昔化け狸の\n群れの中で育ったからさ。" },
	{ "speaker": "akane", "expression": "hohoemi", "bubble": "hukidasi (1)", "text": "ふーん。" },
	{ "speaker": "ponsuke", "expression": "confuse", "bubble": "hukidasi (4)", "text": "お、親分、今大変なんです。" },
	{ "speaker": "ponsuke", "expression": "aseri", "bubble": "hukidasi (3)", "text": "なんだか力があふれて……\nうわああああ！" },
	{ "speaker": "akane", "expression": "aseri", "bubble": "hukidasi (1)", "text": "桜、こいつ襲い掛かってくるお！" },
	{ "speaker": "sakura", "expression": "surprise", "bubble": "hukidasi (1)", "text": "ぽん助まで暴走の餌食に……！" },
	{ "speaker": "sakura", "expression": "oko", "bubble": "hukidasi (2)", "text": "待ってて、今助けるからね！" },
]

var dialogue_afterbattle = [
	{ "speaker": "ponsuke", "expression": "boro", "bubble": "hukidasi (4)", "text": "うう、やっぱり\n親分は強いです……。" },
	{ "speaker": "sakura", "expression": "smile", "bubble": "hukidasi (1)", "text": "あはは、親分が子分に\n負けるわけないじゃん。" },
	{ "speaker": "akane", "expression": "normal", "bubble": "hukidasi (1)", "text": "桜、盛り塩置いておいたお！" },
	{ "speaker": "sakura", "expression": "niko", "bubble": "hukidasi (1)", "text": "ありがと！\nよし、これで二つ目も完了っと。" },
	{ "speaker": "akane", "expression": "surprise", "bubble": "hukidasi (1)", "text": "えーっと、次は確か三叉路で……" },
	{ "speaker": "sakura", "expression": "oko", "bubble": "hukidasi (2)", "text": "最初にすれ違った人に\nお稲荷さんを渡せですって？" },
	{ "speaker": "sakura", "expression": "oko", "bubble": "hukidasi (1)", "text": "何この変な内容！\nふざけてんの？" },
	{ "speaker": "akane", "expression": "confuse", "bubble": "hukidasi (1)", "text": "ママは一体明音たちに\n何をさせたいんだお……？" },
	{ "speaker": "sakura", "expression": "serious", "bubble": "hukidasi (1)", "text": "まあしゃあない。\nこれも大金のためなんだから。" },
	{ "speaker": "sakura", "expression": "oko", "bubble": "hukidasi (1)", "text": "さて、じゃあ三叉路のある…福祥寺駅に行きましょうか。" },
	{ "speaker": "ponsuke", "expression": "boro", "bubble": "hukidasi (4)", "text": "…なんだかよく分からないけど、頑張ってくださいね、親分。" },
]

func _ready():
	hide()
	Global.is_talking = false
	var stage = get_parent().get_node("stagemanager_2")  # 親から子を探す
	stage.connect("stage_cleared", Callable(self, "_on_stage_cleared"))
	
		# ▼ここを追加：ボスの「戦闘終了」シグナルと会話開始を接続
	if is_instance_valid(boss_node):               # ノードが存在するかを安全に確認
		boss_node.connect("battle_ended", Callable(self, "_on_battle_ended"))
	else:
		# もしボスがあとから生成される構成なら、少し遅らせて接続（シーン読み込み直後の安全策）
		call_deferred("_try_connect_boss_signal")
	
func _try_connect_boss_signal() -> void:
	# あとから生成された場合の拾い直し。パス固定が不安ならグループでもOK（下に別案あり）
	if boss_node == null:
		if has_node("../ponsuke"):
			boss_node = get_node("../ponsuke")
	if is_instance_valid(boss_node) and not boss_node.is_connected("battle_ended", Callable(self, "_on_battle_ended")):
		boss_node.connect("battle_ended", Callable(self, "_on_battle_ended"))
	
	
	
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
		if dialogue_index == 14:
			boss_node.visible = true
			emit_signal("dialogue_finished")
			boss_node.set_boss_battle_gate(true)
		if dialogue_index == 3 and not is_after_battle:
			if boss_node:
				boss_node.show()      # まず見えるようにする
				boss_node._boss_show() # 非同期は気にせず呼ぶ
		if dialogue_index == 9:
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

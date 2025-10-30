extends CanvasLayer

@onready var left_character := $akane         # 明音
@onready var right_character_1 := $sakura    # 桜
@onready var right_character_2 := $sanosuke_img    
@onready var name_label := $Namelabel
@onready var message_label := $dialogue
@onready var message_panel := $hukidasi         # 吹き出し背景
@onready var animeplayer := $Anime_ponsuke_name
#@onready var boss_node = get_node("../ponsuke")  
signal dialogue_finished

var dialogue = []  # 現在の会話セット
var dialogue_index := 0
var appeared_characters := []
var is_after_battle := false  # 戦闘後会話ならtrueにする
var is_dialogue_running := false    # ★会話入力を受け付けて良いかのフラグ



# 会話データ（画像ファイル名をそのまま使う形）
var dialogue_beforebattle = [
	{ "speaker": "sakura", "expression": "normal", "bubble": "hukidasi (1)", "text": "さて、三叉路についたわけだけど。" },
	{ "speaker": "sakura", "expression": "magao", "bubble": "hukidasi (1)", "text": "おかしいわね、さっきから\n誰ともすれ違わないなんて。" },
	{ "speaker": "akane", "expression": "normal", "bubble": "hukidasi (1)", "text": "見て、桜！\nあの人のことじゃないかお？" },
	{ "speaker": "sanosuke", "expression": "surprise", "bubble": "hukidasi (4)", "text": "……ん？君たちから\nお稲荷さんの匂いがするね。" },
	{ "speaker": "sanosuke", "expression": "smile", "bubble": "hukidasi (4)", "text": "そのお稲荷さん、僕にちょうだいよ。" },
	{ "speaker": "sakura", "expression": "surprise", "bubble": "hukidasi (1)", "text": "（なんだコイツ…。）" },
	{ "speaker": "sakura", "expression": "confuse", "bubble": "hukidasi (1)", "text": "うん、いいわよ。\nはい、あげる。" },
	{ "speaker": "akane", "expression": "smile2", "bubble": "hukidasi (1)", "text": "よし！これにて\nおつかい三つ目完了なんだお！" },
	{ "speaker": "sanosuke", "expression": "surprise", "bubble": "hukidasi (4)", "text": "…………。" },
	{ "speaker": "sanosuke", "expression": "smile", "bubble": "hukidasi (4)", "text": "……待て、やはり君たちを\nこの先に進めるわけにはいかない。" },
	{ "speaker": "sanosuke", "expression": "kaigan_normal", "bubble": "hukidasi (4)", "text": "なんたってこれは体験版だからね！" },
	{ "speaker": "sakura", "expression": "surprise", "bubble": "hukidasi (1)", "text": "は、はぁ？\n何言ってんのアンタ。" },
	{ "speaker": "sanosuke", "expression": "kaigan_normal", "bubble": "hukidasi (4)", "text": "仕方ない。\n今までのことは夢だとでも思ってくれ。" },
	{ "speaker": "sanosuke", "expression": "kaigan_smile", "bubble": "hukidasi (4)", "text": "じゃあ、おやすみ。" },
	{ "speaker": "sanosuke", "expression": "kaigan_normal", "bubble": "hukidasi (4)", "text": "（お稲荷さん、食べたかった……。）" },
	{ "speaker": "akane", "expression": "aseri", "bubble": "hukidasi (1)", "text": "う、うぅ、なんだか急に眠く…。" },
	{ "speaker": "sakura", "expression": "confuse", "bubble": "hukidasi (1)", "text": "まだ、おつかい…\n終わって…ないのに…。" }
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
	var stage = get_parent()  # 親から子を探す
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
	is_dialogue_running = true              # ★入力受付ON
	set_process_unhandled_input(true)       # ★_unhandled_input を有効化
	show_next_line()

func _unhandled_input(event):
	if not is_dialogue_running:             # ★未開始や終了後なら無視
		return
	if not self.visible:                    # ★念のため非表示なら無視
		return
	if event.is_action_pressed("ui_accept"):# 決定で次の行へ
		show_next_line()
		get_viewport().set_input_as_handled() # 他へ伝播しない保険（任意）

func show_next_line():
	if dialogue.is_empty():                 # ★会話未設定の早押し対策
		return
	if dialogue_index >= dialogue.size():   # 末尾まで進んだら閉じる
		hide_dialogue()
		return
		
	if not is_after_battle:
		if dialogue_index == 13:
			#boss_node.visible = true
			emit_signal("dialogue_finished")
			#boss_node.set_boss_battle_gate(true)
		if dialogue_index == 9:
			name_label.text = "伊賀専 佐之助"
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
		"sanosuke":
			set_expression(right_character_2, "sanosuke", expression)
			set_character_active(left_character, false)
			set_character_active(right_character_1, false)
			set_character_active(right_character_2, true)

	# 対象のノードを取得
	var character_node: TextureRect
	if speaker == "sakura":
		character_node = right_character_1
	elif speaker == "akane":
		character_node = left_character
	elif speaker == "sanosuke":
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
	self.visible = false                    # レイヤー非表示
	Global.is_talking = false               # 会話フラグOFF
	is_dialogue_running = false             # ★入力受付OFF
	set_process_unhandled_input(false)      # ★_unhandled_input停止
	Global.go_to_ending()              

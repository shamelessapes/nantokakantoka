extends Control

# 画像ごとに複数テキストを持てる形式に変更（textsが配列）
var story_data = [
	{ "image": "res://image/Demo_only/無題1192_20250629204910.png", "texts": [
		"桜「な、なにーーーーっ！！」",
		"桜「こ、これは......⁈」",
		"桜「......。」",
		"桜「今まで遊んでいたゲームは⁈」",
		"明音ママ「ふふふ...残念ながらこれでもう終わりよ。」",
		"明音ママ「なぜかってこれは、体験版ですからね！」",
		"桜「た、体験版ですってーーー⁈」",
		"桜「バカじゃないの、ふつうゲームってものは\n　人に遊んでもらうときには完成させておくものでしょ！」",
		"明音ママ「ふふ…誰かに遊んで貰いたい、褒めてほしい…\n　　　　そんな承認欲求からクリエイターは完成してもいない進捗を見せびらか\n　　　　す。」",
		"明音ママ「この体験版も、そんなしょうもない承認欲求から産まれたの。」"
	]},
	{ "image": "res://image/Demo_only/無題1192_20250629204916.png", "texts": [
		"桜「にしても酷すぎるわ。私まだ雑魚一匹しか倒してないのに！」",
		"明音ママ「ええそうね。この体験版では、雑魚一匹としか戦えないわ。」",
		"明音ママ「でも安心しなさい、桜。\n　　　　このゲームは恐らく秋には完成するわ！」"
	]},
	{ "image": "res://image/Demo_only/無題1192_20250629204922.png", "texts": [
		"明音ママ「なんと、製品版では......!」",
		"明音ママ「ウチのかわいい娘もプレイヤーとして操作できるわ！」",
		"桜「私だけじゃなくて明音も⁈それは嬉しいわね。」"
	]},
	{ "image": "res://image/Demo_only/無題1192_20250629204926.png", "texts": [
		"明音ママ「しかもそれだけじゃない。」",
		"明音ママ「あの顔芸傘野郎だけじゃなく、\n　　　　他にも魅力的なキャラクターが沢山登場するわよ。」",
		"桜「やったー！頼むから人型のキャラに出てきてほしいわね。」"
	]},
	{ "image": "res://image/Demo_only/無題1192_20250629204931.png", "texts": [
		"明音ママ「あと音楽も全て自作曲に差し替えるわ。」",
		"桜「フリーBGMも悪くないけど、個性を出したいものね。」",
		"明音ママ「ちなみにセール最終日だったから\n　　　　昨日やっとstudio oneを購入したの。」",
		"桜「おっそ。」"
	]},
	{ "image": "res://image/Demo_only/無題1192_20250629204936.png", "texts": [
		"明音ママ「あとエンディングは、スコアに応じたマルチエンディング\n　　　　を予定してるわ。」",
		"桜「なるほど、やりこみ要素も用意してるってわけ。」"
	]},
	{ "image": "res://image/Demo_only/無題1192_20250629204941.png", "texts": [
		"明音ママ「あとXキーで必殺技が出せるようになるわ。」",
		"桜「ありがたい！ちょうど夢〇封印したくてウズウズしてたところよ。」",
		"明音ママ「コラ！いくらシステムが似てるからって\n　　　　具体的な技名を出すんじゃないの！」"
	]},
	{ "image": "res://image/Demo_only/無題1192_20250629204946.png", "texts": [
		"明音ママ「…ちなみに全５ステージ+EXにしようと思ってるわ」",
		"桜「６ステージもあると集中力もたないもんね！」"
	]},
	{ "image": "res://image/Demo_only/無題1192_20250629204959.png", "texts": [
		"明音ママ「というわけで、完成版をお楽しみに！」",
		"明音ママ「ちなみに８月には３ステージまで作った\n　　　　体験版その２を出すつもりよ！」",
		"桜「ダメなクリエイターあるある、進捗やたら見せがち。」",
		"明音ママ「そこ、うるさいわよ。」",
		"明音ママ「…それじゃあ早ければ約２か月後に、またお会いしましょう。」",
		"桜「ばいば～い。」"
	]},
]

var current_index := 0         # 何枚目の絵か
var current_text_index := 0    # 今見ている絵の中の何個目のテキストか
var is_showing := false  # テキストを1文字ずつ表示中かどうか
var current_text := ""  # 表示中の全文
var normal_speed := 0.08
var fast_speed := 0.01
var text_speed := normal_speed
var skip_mode := false
var skip_timer := 0.0


@onready var bg = $TextureRect
@onready var text_label = $Panel/RichTextLabel
@onready var next_hint = $Panel/Label
@onready var skip_all_button = $SkipButton


func _ready():
	Global.fade_in(Color.WHITE)
	SoundManager.play_se_by_path("res://se/game_explosion2.mp3",-5)
	$AudioStreamPlayer2D.play()
	show_story_page(current_index)
	skip_all_button.pressed.connect(_on_skip_all_button_pressed)

func _process(delta):
	if next_hint.visible:
		var t = Time.get_ticks_msec() / 500.0
		next_hint.modulate.a = 0.5 + 0.5 * sin(t)
	# ZキーまたはCtrlキー長押し中ならスピード変更
	if Input.is_action_pressed("ui_accept") or Input.is_key_pressed(KEY_CTRL):
		text_speed = fast_speed
		skip_mode = true
	else:
		text_speed = normal_speed
		skip_mode = false
	# skip_mode中かつ全文表示済みなら、自動で次の文章へ
	if skip_mode and not is_showing and next_hint.visible:
		skip_timer += delta
		if skip_timer > 0.1:
			skip_timer = 0.0
			safe_show_text_list()
	else:
		skip_timer = 0.0  # ← これを if文の外に！



# 1枚の絵の表示開始（テキストは最初の1個目から）
func show_story_page(index: int):
	if index >= story_data.size():
		end_story()
		return
	var page = story_data[index]
	bg.texture = load(page["image"])
	current_text_index = 0
	show_text_list(page["texts"])


func safe_show_text_list():
	if current_index >= story_data.size():
		end_story()
		return
	var texts = story_data[current_index]["texts"]
	show_text_list(texts)

# texts配列の中から1個ずつタイプライター表示
func show_text_list(texts: Array) -> void:
	if is_showing:
		return
	if current_text_index >= texts.size():
		current_index += 1
		current_text_index = 0  # 忘れずリセット！
		# ここにも保険入れるとさらに安心
		if current_index >= story_data.size():
			end_story()
			return
		show_story_page(current_index)
		return
	is_showing = true
	text_label.clear()
	next_hint.visible = false
	current_text = texts[current_text_index]
	current_text_index += 1
	for char in current_text:
		text_label.append_text(char)
		await get_tree().create_timer(text_speed).timeout
		if not is_showing:
			return
	next_hint.visible = true
	is_showing = false


func show_previous_text():
	if is_showing:
		return
	current_text_index -= 2
	if current_text_index < 0:
		current_index -= 1
		if current_index < 0:
			current_index = 0
			current_text_index = 0
			return
		current_text_index = story_data[current_index]["texts"].size() - 1

	safe_show_text_list()


func _unhandled_input(event):
	if event.is_action_pressed("ui_accept"):
		if is_showing:
			# スキップ全文表示
			is_showing = false
			text_label.clear()
			text_label.append_text(current_text)
			next_hint.visible = true
		else:
			safe_show_text_list()  # ← ここでちゃんと次の文を表示する
	elif event.is_action_pressed("ui_backtext"):
		show_previous_text()



func _on_skip_all_button_pressed():
	SoundManager.play_se_by_path("res://se/決定ボタンを押す49.mp3")
	end_story() 

func end_story():
	await get_tree().create_timer(1.5).timeout
	Global.change_scene_with_fade("res://tscn/title_demo.tscn", Color.BLACK)

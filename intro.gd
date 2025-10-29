extends Control

var is_ending := false  # ← 終了処理に入ったらtrue。以後の入力・進行を無視

# 画像ごとに複数テキストを持てる形式に変更（textsが配列）
var story_data = [
	{ "image": "res://image/プロローグ/5.png", "texts": [
		"東京都にある六つ目の町、与座蔵町。",
		"この町はとある噂で有名だった。"
	]},
	{ "image": "res://image/プロローグ/6.png", "texts": [
		"そう、その噂とは……"
	]},
	{ "image": "res://image/プロローグ/7.png", "texts": [
		"妖怪が出るというものである。",
		"実際に、与座蔵町ではひとりでに物が浮いたり、\n人やモノが消えたり、",
		"身に覚えのない請求が来たり、執拗に「オレ」と名乗る人物から\n電話がかかってきたり……。",
		"＿＿このように町の住人は、姿の見えない怪異に日々頭を悩ませていた。"
	]},
	{ "image": "res://image/プロローグ/8.png", "texts": [
		"これはそんな与座蔵町に住む２人の女子高生、\n半妖の桜と巫女の明音の物語である。"
	]},
	{ "image": "res://image/プロローグ/9.png", "texts": [
		"これはそんな与座蔵町に住む２人の女子高生、\n半妖の桜と巫女の明音の物語である。"
	]},
	{ "image": "res://image/プロローグ/10.png", "texts": [
		"これはそんな与座蔵町に住む２人の女子高生、\n半妖の桜と巫女の明音の物語である。"
	]},
	{ "image": "res://image/プロローグ/11.png", "texts": [
		"これはそんな与座蔵町に住む２人の女子高生、\n半妖の桜と巫女の明音の物語である。"
	]},
	{ "image": "res://image/プロローグ/12.png", "texts": [
		"これはそんな与座蔵町に住む２人の女子高生、\n半妖の桜と巫女の明音の物語である。"
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
	Global.fade_in(Color.BLACK)
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
	elif event.is_action_pressed("ui_skip"):  # ← Sキーでスキップ
		SoundManager.play_se_by_path("res://se/決定ボタンを押す49.mp3")
		end_story()  # 即スキップ



func _on_skip_all_button_pressed():
	if is_ending:                      # ← 多重押し防止
		return
	SoundManager.play_se_by_path("res://se/決定ボタンを押す49.mp3")
	end_story()

func end_story():
	if is_ending:                      # ← すでに終了中なら何もしない
		return
	is_ending = true                   # ← ここで終了状態に固定
	set_process_unhandled_input(false) # ← 入力ハンドリングを止める（保険）
	next_hint.visible = false          # ← 点滅ヒントも非表示
	skip_all_button.disabled = true    # ← スキップボタンも無効化（保険）

	# 1.5秒の余韻中に連打されても上のフラグで無効化される
	await get_tree().create_timer(1.5).timeout
	Global.change_scene_with_fade("res://tscn/main.tscn", Color.BLACK)

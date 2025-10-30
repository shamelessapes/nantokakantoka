extends Control

var is_ending = false

# 画像ごとに複数テキストを持てる形式に変更（textsが配列）
var story_data = [
	{ "image": "res://image/エンディング(共通)/e1.png", "texts": [
		" ……気がつくと桜たちは、明音の家の前で倒れていた。 ",
		"桜「 い、一体何だったのよ……。」",
		"明音「アイツが言ってたタイケンバン？とかって結局なんのことなんだお！？」",
		" 2人が背中の汚れを払いながらブツクサ文句を垂れていると、"
	]},
	{ "image": "res://image/エンディング(共通)/e2.png", "texts": [
		" 綾音「……あら、2人ともおかえりなさい。早かったわね。」",
		"ガチャ、という玄関の音とともに明音の母、綾音が姿を現した。",
		"明音「あ、ママー！聞いてお、明音たち大変だったんだおー！？」",
		"桜「そうよ、私たち頑張っておつかいしてたのに、\nタイケンバンだからとか言われて気がついたらここに……！」 ",
		"綾音「……あら、それは大変だったわね。」",
		"明音の母は何かを察したかのように目を見開くと、\nその後すぐに、何事も無かったかのようにすぐに落ち着きを取り戻した。",
		"綾音「ところで、頑張った2人にはおつかいの報酬をあげないといけないわね。」",
		"桜「え！！おつかい全部終わってないのに、貰っちゃっていいの！？」"
		
	]},
	{ "image": "res://image/エンディング(共通)/e3.png", "texts": [
		" 綾音「ええ、あげるわよ。」 ",
		" 綾音「それで2人のスコアは、どれどれ……」 "
	]},
	{ "image": "res://image/エンディング(共通)/End2/END2_1.png", "texts": [
		"綾音「…… %d 点ね。」" % Global.score ,
		"綾音「まあ、普通ね。及第点ってところかしら。」 ",
		"綾音「でもまあ頑張ってくれたことだし、スコアに応じた金額を報酬として支払いましょう。」",
		"桜「ほんとに！？やったー！！」",
		"明音「やったお！JKにしては結構な大金だおね！？」",
		"綾音「こら、調子に乗らない。これに満足せず、今後も精進なさい。」",
		"2人「うーーーい。」",
		"明音「……ところで桜、このお金どう使うつもりなんだお？」",
		"桜「そうね、どうしよう……。」",
		"桜「そうだ、宝くじに使いましょ！もっと増えて返ってくるかも！」",
		"明音「いいおねー！！さっすが桜、天才なんだお。」"
	]},
	{ "image": "res://image/エンディング(共通)/End2/END2_2.png", "texts": [
		"……数ヶ月後",
		"桜「……まさか増えて返ってくるどころか、半額以下になって返ってくるとは。」",
		"明音「世知辛い世の中だおね……。」",
		"桜「でもこんなところで諦めてはだめよ！そろそろ確率が収束するはずだわ。」",
		"桜「そろそろ1等が当たる予感がするの！」 ",
		"明音「うおお！それはやるしかないおね。」 ",
		"桜「さあ、また売り場に行くわよ！」",
		"明音「おー！目指せ、億万長者！」",
		"エンド2 ギャンブラー",
		"<fade_out:0.8:black>", 
		"<wait:0.2>"
	]},
	{ "image": "res://image/エンディング(共通)/e4.png", "texts": [
		"<fade_in:0.8:black>",
		"佐之助「やあ、こんにちは。さっきは中断しちゃってごめんね。」",
		"佐之助「さっきも言ったけどさ、これ体験版なんだよね。」",
		"佐之助「だから僕にお稲荷さんを渡したかったら、製品版の方を遊んでくれ。」",
		"佐之助「え？いつ製品版は出るのかって？」",
		"佐之助「……まあ早くて来年六月くらいじゃない？」"
	]},
	{ "image": "res://image/エンディング(共通)/e5.png", "texts": [
		"佐之助「それじゃ、体験版を遊んでくれてありがとね。」",
		"佐之助「いつ出るか分からない製品版を楽しみに待っててくれ。」",
		"佐之助「あ、感想とかくれると凄い制作の励みになるよ。」",
		"佐之助「じゃあね。」",
		"佐之助「…………。」",
		"佐之助「…………君さ、今お稲荷さん持ってたりしないかい？」"
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
		current_text_index = 0
		if current_index >= story_data.size():
			end_story()
			return
		show_story_page(current_index)
		return

	is_showing = true
	text_label.clear()
	next_hint.visible = false

	current_text = texts[current_text_index]   # ← 今回表示する行
	current_text_index += 1                    # ← 先にインデックスを進める（戻る処理は別で調整済）

	# === ここでコマンド行を処理（タイプ表示しない） ===
	if await _try_handle_command_line(current_text):  # ← await を追加
		is_showing = false
		safe_show_text_list()
		return


	# === ここから通常のタイプライター表示 ===
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


func _parse_color(s: String) -> Color:
	var key := s.to_lower()
	if key == "black":
		return Color.BLACK
	if key == "white":
		return Color.WHITE
	if key.begins_with("#"):
		return Color(key)
	return Color.BLACK

# === コマンド行かどうか判定して実行。実行したら true を返す ===
func _try_handle_command_line(line: String) -> bool:
	# 先頭と末尾が <> で囲まれていないならコマンドではない
	if not (line.begins_with("<") and line.ends_with(">")):
		return false

	# 例: "<fade_out:1.0:black>" -> "fade_out:1.0:black"
	var inner := line.substr(1, line.length() - 2)
	var parts := inner.split(":")
	var cmd := parts[0].to_lower()

	match cmd:
		"fade_out":
			var dur := 1.0
			var col := Color.BLACK
			if parts.size() >= 2: dur = float(parts[1])
			if parts.size() >= 3:
				col = _parse_color(parts[2])


			await Global.fade_out(col, dur)           # 用意済みの関数を使用
			return true

		"fade_in":
			var dur := 1.0
			var col := Color.BLACK   # 「黒から開ける」画にしたい場合は黒に
			if parts.size() >= 2: dur = float(parts[1])
			if parts.size() >= 3:
				col = _parse_color(parts[2])

			await Global.fade_in(col, dur)            # 用意済みの関数を使用
			return true

		"wait":
			var t := 0.3
			if parts.size() >= 2: t = float(parts[1])
			await get_tree().create_timer(t).timeout
			return true

		_:
			# 未知コマンドは無視して通常表示に回す
			return false



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
	Global.change_scene_with_fade("res://tscn/mikotsuka_title.tscn", Color.BLACK)

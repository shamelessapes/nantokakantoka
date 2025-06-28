extends Control

# 画像ごとに複数テキストを持てる形式に変更（textsが配列）
var story_data = [
	{ "image": "res://image/プロローグ/prorogue1.png", "texts": [
		"令和××年。",
		"東京都５つ目の町、与座蔵（よざくら）町＿＿。",
		"緑豊かで、それでいて都会過ぎない平凡な町。",
		"しかしこの町にはひとつ大きな問題があった。"
	]},
	{ "image": "res://image/プロローグ/prorogue2.png", "texts": [
		"............。",
		"妖怪、幽霊にその他魑魅魍魎......。\nそう、ここは自称「日本で一番怪異が多い町」なのである！",
		"物が勝手に落ちてきたり、姿の見えない何かとぶつかったり、\n自称心霊系Youtuberがやってきたり、スマホのバッテリーがやたらすぐ減ったり、",
		"お通じの調子が悪かったり、米の値段が上がったり、\nタンスの角に小指をぶつける頻度が増えたり、頑張って働いてるのに給料は\nいつまでたっても上がらなかったり......。",
		".......まあ全部妖怪の仕業なのかは微妙だが、それはそれとして\nここに住む人間たちはみな、姿の見えない怪異に頭を悩ませていた。"
	]},
	{ "image": "res://image/プロローグ/prorogue3.png", "texts": [
		"......しかーーーし！\nこの与座蔵町最強コンビが来たからには安心だ！"
	]},
	{ "image": "res://image/プロローグ/prorogue4.png", "texts": [
		"華月 桜（画面左）と神宮 明音（画面右）。\nどちらも与座蔵町の高校に通う女子高生である。",
		"しかもこの２人、ただのJKではない。",
		"桜は妖怪と人間のハーフ、半妖。",
		"明音は由緒ある神社の巫女さん。",
		"この二人がタッグを組めば、倒せない怪異なんていないのである！"
	]},
	{ "image": "res://image/プロローグ/prorogue5.png", "texts": [
		"そんな２人はある日、同じく巫女である明音ママから突然呼び出しを食らう。",
		"２人は神宮家の客間へと案内された。"
	]},
	{ "image": "res://image/プロローグ/prorogue6.png", "texts": [
		"桜「明音ママ、一体どうしたのよ？突然呼び出したりして。」",
		"明音「そうだお、なんか真面目な雰囲気だけど一体どうしたのかお？」",
		"明音ママ「そうね、突然呼び出したりしてごめんなさいね。」",
		"明音ママ「実はね......あなたたち２人に頼みたいことがあるのよ。」",
		"桜＆明音「「頼みたいこと？」」",
		"明音ママ「ええ、それはね......」"
	]},
	{ "image": "res://image/プロローグ/prorogue7.png", "texts": [
		"明音ママ「あなたたち２人に“おつかい”に行ってきて欲しいの。」",
		"桜＆明音「............。」",
		"桜「お、おつかい！？\n　　......なんか買ってきてほしいものでもあるの？」",
		"明音ママ「いや、別にそういうわけじゃないわ。\n　　　　おつかいじゃなくて“おつかい”を頼みたいの。」",
		"明音ママは、“お・つ・か・い”とわざとらしく発音した。",
		"明音「ねえママ、明音よくわかんないお～。\n　　それっていわゆる普通のおつかいとなにが違うの？」",
		"明音ママ「はぁ......時間がないから説明は今は省くわね。。\n　　　　あのね、要するに単刀直入にいうとね......」"
	]},
	{ "image": "res://image/プロローグ/prorogue8.png", "texts": [
		"明音ママ「......この町で起きている異変を解決してきて欲しいの。」",
		"桜＆明音「えぇ～～～～～～！？」",
		"桜「めんどくさ。嫌なんだけど。」",
		"明音「いやそれな？明音たちこれから遊びに行く予定だったんだお！？」",
		"明音ママ「まあまあ、とりあえず聞いてちょうだいな。\n　　　　今この町の妖怪がやたら活発になってるのは、あなたたちも知ってる\n　　　　わよね？」",
		"桜「ええ、もちろんよ。あいつらウザイったらありゃしない！\n　いつもならワンパンで倒せるのに、最近やたらしぶといし活動的よね。」",
		"明音ママ「その妖怪活性化の原因を突き止めて、解決してきて欲しいのよ。」",
		"明音「ええっ、なんか大変そうだおね......。」",
		"明音ママ「そうね、解決のためには恐らくこの町中を東奔西走する\n　　　　必要があるでしょう。」",
		"明音ママ「だからといってはなんだけど、ちゃんと報酬も用意したのよ？」",
		"桜「え？報酬！？\n　まさか二万円とか？そんなんじゃ靡かないわよ。」",
		"明音ママ「ふふ、そんなんじゃないわよ。」",
		"明音ママ「そうねぇ、最高で.......」"
	]},
	{ "image": "res://image/プロローグ/prorogue9.png", "texts": [
		"明音ママ「１００万円とかどう？」",
		"桜「やる、やります。」",
		"明音「は、判断が早すぎるんだお......!」",
		"明音ママ「ふふ、じゃあ決まりね。」",
		"明音ママ（最大で１００万円って意味なんだけど......\n　　　　まぁいっか。）"
	]},
	{ "image": "res://image/プロローグ/prorogue10.png", "texts": [
		"明音ママ「それじゃあふたりとも、いってらっしゃい。」",
		"明音ママ「.......そうだ、“おつかい”にはこれも持って行ってね。」",
		"桜「なにこれ、いなり寿司？」",
		"明音「これなにに使うんだお～？」",
		"明音ママ「まぁまぁ、そのうち分かるわ。」",
		"桜「......な～んかさっきから説明が腑に落ちないわね。」",
		"明音ママ「でも報酬１００万円だお？やるっきゃないお！」",
		"こうしてお金にがめつい2人は、何だかよく分からないまま\n“おつかい”へと向かうのだった＿＿。"
	]}
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
@onready var fade_rect = $ColorRect
@onready var next_hint = $Panel/Label
@onready var skip_all_button = $SkipButton


func _ready():
	fade_in()
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
	end_story()  # ←ここだけでOK！

func end_story():
	fade_out()
	await get_tree().create_timer(3.0).timeout
	get_tree().change_scene_to_file("res://tscn/main.tscn")

# フェードイン（黒→透明）
func fade_in():
	fade_rect.color.a = 1.0
	var tween = create_tween()
	tween.tween_property(fade_rect, "color:a", 0.0, 1.0)

# フェードアウト（透明→黒）
func fade_out():
	var tween = create_tween()
	tween.tween_property(fade_rect, "color:a", 1.0, 1.0)

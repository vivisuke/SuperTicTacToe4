extends Node2D

const N_VERT = 9
const N_HORZ = 9
const NEXT_LOCAL_BOARD = 0
#const MARU = 1
#const BATSU = 0
const WAIT = 6*3
const GVAL = 100

const g_pow_table = [	pow(3, 8), pow(3, 7), pow(3, 6),
						pow(3, 5), pow(3, 4), pow(3, 3),
						pow(3, 2), pow(3, 1), pow(3, 0), ]
const mb_str = ["Ｘ", "・", "Ｏ"]
enum {
	BLACK = -1, EMPTY, WHITE,				#	盤面石値、WHITE for 先手
	#TS_EMPTY = -1, TS_BATSU, TS_MARU,		#	タイルセットID
	TS_EMPTY = -1, TS_WHITE, TS_BLACK,		#	タイルセットID
	HUMAN = 0, AI_RANDOM, AI_DEPTH_1, AI_DEPTH_2, AI_DEPTH_3, AI_DEPTH_4, AI_DEPTH_5, 
}


const LINED3 = 100;				#	3目並んだ
const LINED2 = 8;				#	2目並んだ
const LINED1 = 1;				#	1目のみ


var BOARD_ORG_X
var BOARD_ORG_Y
var BOARD_ORG

var g = Global
var rng = RandomNumberGenerator.new()
var AI_thinking = false
var waiting = 0;				# ウェイト中カウンタ
var game_started = false		# ゲーム中か？
#var white_player = HUMAN
#var black_player = HUMAN
var pressedPos = Vector2(0, 0)
var print_eval_ix = -1			# -1 for 非表示
var move_hist = []				# 着手履歴
#var g.bd			# 盤面オブジェクト
var g_board3x3 = []			# 3x3 盤面 for 作業用
var g_eval_table = []		# 盤面インデックス→評価値 テーブル
var g_eval_labels = []
var shock_wave_timer = -1

func _ready():
	#rng.randomize()		# Setups a time-based seed
	rng.seed = 0		# 固定乱数系列
	BOARD_ORG_X = $Board/TileMapLocal.global_position.x
	BOARD_ORG_Y = $Board/TileMapLocal.global_position.y
	BOARD_ORG = Vector2(BOARD_ORG_X, BOARD_ORG_Y)
	build_3x3_eval_table()			# 3x3盤面→評価値テーブル構築
	build_eval_labels()				# 各セルに評価値表示用ラベル設置
	#g.bd = Board.new()
	#g.bd.m_rng = rng
	#g.bd.set_eval_table(g_eval_table)
	init_board()
	update_next_underline()
	update_board_tilemaps()		# g.bd の状態から TileMap たちを設定
	g.bd.print()
	$WhitePlayer/OptionButton.select(g.white_player)
	$BlackPlayer/OptionButton.select(g.black_player)
	$MessLabel.text = "【Start Game】を押してください。"
	$CanvasLayer/ColorRect.material.set("shader_param/size", 0)
	pass
func build_eval_labels():
	for y in range(N_VERT):
		for x in range(N_HORZ):
			var lbl = Label.new()
			lbl.text = ""
			lbl.position = Vector2(x*51+25, y*51+35)
			lbl.modulate = Color(1, 0, 0) # 赤色
			$Board.add_child(lbl)
			g_eval_labels.push_back(lbl)
func init_board():
	#g.bd.init()
	update_board_tilemaps()		# g.bd の状態から TileMap たちを設定
	move_hist = []
	$NStoneLabel.text = "#1 (spc: 81)"
	$MessLabel.text = "【Start Game】を押してください。"
func on_game_over():
	print("on_game_over()")
	game_started = false
	$HBC/RuleButton.disabled = game_started
	$WhitePlayer/OptionButton.disabled = false
	$BlackPlayer/OptionButton.disabled = false
	$InitButton.disabled = false
	$StartStopButton.disabled = true
	$StartStopButton.text = "▶ Cont. Game"
	update_board_tilemaps()
	$CanvasLayer/ColorRect.show()
	shock_wave_timer = 0.0      # start shock wave
func update_next_underline():
	$WhitePlayer/Underline.visible = game_started && g.bd.next_color() == WHITE
	$BlackPlayer/Underline.visible = game_started && g.bd.next_color() == BLACK
func update_nstone():
	$NStoneLabel.text = "#%d (spc: %d)" % [g.bd.m_nput+1, 81-g.bd.m_nput]
func col2tsid(col):
	match col:
		EMPTY:	return TS_EMPTY
		WHITE:	return TS_WHITE
		BLACK:	return TS_BLACK
func tsid2col(id):
	match id:
		TS_EMPTY:	return EMPTY
		TS_WHITE:	return WHITE
		TS_BLACK:	return BLACK
func update_board_tilemaps():		# g.bd の状態から TileMap たちを設定
	for y in range(N_VERT):
		for x in range(N_HORZ):
			$Board/TileMapLocal.set_cell(0, Vector2i(x, y), col2tsid(g.bd.get_color(x, y)), Vector2i(0, 0))
			$Board/TileMapCursor.set_cell(0, Vector2i(x, y), (0 if g.bd.last_put_pos() == [x, y] else -1), Vector2i(0, 0))
	var ix = 0
	for y in range(N_VERT/3):
		for x in range(N_HORZ/3):
			var c = -1 if g.bd.next_board() >= 0 && ix != g.bd.next_board() else NEXT_LOCAL_BOARD
			$Board/TileMapBG.set_cell(0, Vector2i(x, y), c, Vector2i(0, 0))
			$Board/TileMapGlobal.set_cell(0, Vector2i(x, y), col2tsid(g.bd.get_gcolor(x, y)), Vector2i(0, 0))
			ix += 1
	pass
func can_put_local(x : int, y : int):
	return $Board/TileMapBG.get_cell_source_id(0, Vector2i(x, y)) == NEXT_LOCAL_BOARD
func eval3(c1, c2, c3):		# 石の値は 0 for 空欄、±1 for 白・黒 と仮定
	var sum = c1 + c2 + c3;
	if( sum == WHITE * 3 ): return LINED3;
	if( sum == BLACK * 3 ): return -LINED3;
	if( sum == WHITE * 2 ): return LINED2;
	if( sum == BLACK * 2 ): return -LINED2;
	var n = c1*c1 + c2*c2 + c3*c3;		#	置かれた石数
	if( n == 1 ):
		if( sum == WHITE ): return LINED1;
		if( sum == BLACK ): return -LINED1;
	return 0;
	pass
func eval3x3(board : Array):
	var ev = 0;
	for i in range(3):
		ev += eval3(board[i*3 + 0], board[i*3 + 1], board[i*3 + 2]);
		ev += eval3(board[0*3 + i], board[1*3 + i], board[2*3 + i]);
	ev += eval3(board[0*3 + 0], board[1*3 + 1], board[2*3 + 2]);
	ev += eval3(board[2*3 + 0], board[1*3 + 1], board[0*3 + 2]);
	return ev;
	pass
func set_board3x3(index : int):
	var i = 8
	while i >= 0:
		match index % 3:
			0:	g_board3x3[i] = EMPTY
			1:	g_board3x3[i] = WHITE
			2:	g_board3x3[i] = BLACK
		index /= 3
		i -= 1
func build_3x3_eval_table():
	g_board3x3.resize(3*3)
	g_eval_table.resize(pow(3, 9))		# 3^9
	for ix in range(g_eval_table.size()):
		set_board3x3(ix);
		g_eval_table[ix] = eval3x3(g_board3x3);
		#print(g_eval_table[ix]);
func update_next_mess():
	if g.bd.next_color() == WHITE:
		$MessLabel.text = "Ｏ の手番です。"
	else:
		$MessLabel.text = "☓ の手番です。"
func put_and_post_proc(x: int, y: int, replay: bool):	# 着手処理とその後処理
	g.bd.put(x, y, g.bd.next_color())
	#g.bd.print()
	if !replay:
		move_hist.resize(g.bd.m_nput-1)
		move_hist.push_back([x, y])
	if g.bd.is_game_over():
		$Audio/Kirakira.play()
		game_started = false
		$HBC/RuleButton.disabled = game_started
		match g.bd.winner():
			EMPTY:	$MessLabel.text = "引き分けです。"
			WHITE:	$MessLabel.text = "○ の勝ちです。"
			BLACK:	$MessLabel.text = "☓ の勝ちです。"
	else:
		if g.bd.m_linedup:		# ローカルボード内で三目並んだ
			$Audio/Don.play()		# 効果音
		update_next_mess()
	update_next_underline()
	update_board_tilemaps()
	update_nstone()
	update_back_forward_buttons()
func _process(delta):
	if waiting > 0:
		waiting -= 1
	elif( game_started && !AI_thinking &&
			(g.bd.next_color() == WHITE && g.white_player >= AI_RANDOM ||
			g.bd.next_color() == BLACK && g.black_player >= AI_RANDOM) ):
		# AI の手番
		#if !game_started:
		#	print("??? game_started = ", game_started)
		AI_thinking = true
		#var pos = AI_think_random()
		var typ = g.white_player if g.bd.next_color() == WHITE else g.black_player
		var pos = (g.bd.select_random() if typ == AI_RANDOM else
					g.bd.select_alpha_beta(typ - AI_RANDOM))
		#print("game_started = ", game_started)
		print("AI put ", pos)
		put_and_post_proc(pos[0], pos[1], false)
		waiting = WAIT
		AI_thinking = false
		if g.bd.is_game_over():
			on_game_over()
	elif print_eval_ix >= 0 && print_eval_ix < N_HORZ*N_VERT:
		# 空欄に評価値を表示
		if g.bd.next_board() < 0:	# 全ローカルボードに着手可能
			if g.bd.is_empty(print_eval_ix%9, print_eval_ix/9):
				g.bd.put(print_eval_ix%9, print_eval_ix/9, g.bd.next_color())
				var ev = min(9999, max(-9999, g.bd.alpha_beta(-2000, 2000, 3)))
				g.bd.undo_put()
				g_eval_labels[print_eval_ix].text = "%d" % ev
			print_eval_ix += 1
			if print_eval_ix >= N_HORZ*N_VERT:
				print_eval_ix = -1
		else:	# g.bd.next_board() にのみ着手可能
			var x0 = (g.bd.next_board() % 3) * 3
			var y0 = (g.bd.next_board() / 3) * 3
			var h = print_eval_ix % 3
			var v = print_eval_ix / 3
			if g.bd.is_empty(x0 + h, y0 + v):
				g.bd.put(x0 + h, y0 + v, g.bd.next_color())
				var ev = min(9999, max(-9999, g.bd.alpha_beta(-2000, 2000, 3)))
				g.bd.undo_put()
				g_eval_labels[x0 + h + (y0 + v)*N_HORZ].text = "%d" % ev
			print_eval_ix += 1
			if print_eval_ix >= 9:
				print_eval_ix = -1
	if shock_wave_timer >= 0:
		shock_wave_timer += delta
		$CanvasLayer/ColorRect.material.set("shader_param/size", shock_wave_timer)
		if shock_wave_timer > 2:
			shock_wave_timer = -1.0
			$CanvasLayer/ColorRect.hide()
	pass

func _input(event):
	if !game_started: return
	if event is InputEventMouseButton && event.button_index == MOUSE_BUTTON_LEFT:
		#print(event.position)
		#print($Board/TileMapLocal.local_to_map(event.position - BOARD_ORG))
		var pos = $Board/TileMapLocal.local_to_map(event.position - BOARD_ORG)
		#print("mouse button")
		if event.is_pressed():
			#print("pressed")
			pressedPos = pos
		elif pos == pressedPos:
			#print("released")
			#if n_put == 0:
			#	game_started = true
			#	return
			if pos.x < 0 || pos.x >= N_HORZ || pos.y < 0 || pos.y > N_VERT: return
			if !g.bd.is_empty(pos.x, pos.y): return
			var gx = int(pos.x) / 3
			var gy = int(pos.y) / 3
			if !can_put_local(gx, gy): return
			put_and_post_proc(pos.x, pos.y, false)
			if g.bd.is_game_over():
				on_game_over()
			waiting = WAIT
	pass

func _on_init_button_pressed():
	$WhitePlayer/OptionButton.disabled = false
	$BlackPlayer/OptionButton.disabled = false
	$StartStopButton.disabled = false
	$StartStopButton.text = "▶ Start Game"
	clear_eval_labels()
	g.bd.init()
	init_board()
	pass # Replace with function body.

func _on_start_stop_button_pressed():
	game_started = !game_started
	$HBC/RuleButton.disabled = game_started
	if game_started:
		$WhitePlayer/OptionButton.disabled = true
		$BlackPlayer/OptionButton.disabled = true
		$InitButton.disabled = true
		$StartStopButton.text = "■ Stop Game"
		clear_eval_labels()
		if g.bd.is_game_over():
			init_board()
		update_next_mess()
	else:
		if !g.bd.is_game_over():
			$WhitePlayer/OptionButton.disabled = false
			$BlackPlayer/OptionButton.disabled = false
			$InitButton.disabled = false
			$StartStopButton.text = "▶ Cont. Game"
		$MessLabel.text = ""
	update_next_underline()
	update_back_forward_buttons()
func _on_White_option_button_item_selected(index):
	g.white_player = index
func _on_Black_option_button_item_selected(index):
	g.black_player = index
func _on_undo_button_pressed():
	if g.bd.m_stack.size() < 2: return
	g.bd.undo_put()
	g.bd.undo_put()
	update_board_tilemaps()
	update_nstone()
func update_eval_labels():
	#if $PrintEvalButton.pressed:
		clear_eval_labels()
		print_eval_ix = 0
func update_back_forward_buttons():
	print("update_back_forward_buttons()")
	$HBC/SkipPrevButton.disabled = game_started || g.bd.m_stack.is_empty()
	$HBC/BackwardButton.disabled = game_started || g.bd.m_stack.is_empty()
	$HBC/ForwardButton.disabled = game_started || move_hist.size() <= g.bd.m_nput
	$HBC/SkipNextButton.disabled = game_started || move_hist.size() <= g.bd.m_nput
	$StartStopButton.disabled = false
func _on_skip_prev_button_pressed():	# 初手まで戻る
	while !g.bd.m_stack.is_empty():
		g.bd.undo_put()
	update_board_tilemaps()
	update_next_mess()
	update_next_underline()
	update_nstone()
	update_back_forward_buttons()
	$StartStopButton.disabled = false
	update_eval_labels()
func _on_backward_button_pressed():		# 戻る
	if g.bd.m_stack.size() < 1: return
	g.bd.undo_put()
	update_board_tilemaps()
	update_next_mess()
	update_next_underline()
	update_nstone()
	update_back_forward_buttons()
	#print("move_hist = ", move_hist)
	update_eval_labels()
func _on_forward_button_pressed():		# 進める
	if move_hist.size() <= g.bd.m_nput: return
	#print("move_hist = ", move_hist)
	var t = move_hist[g.bd.m_nput]
	put_and_post_proc(t[0], t[1], true)
	update_eval_labels()
func _on_skip_next_button_pressed():	# 最後まで進める
	while move_hist.size() > g.bd.m_nput:
		var t = move_hist[g.bd.m_nput]
		put_and_post_proc(t[0], t[1], true)
	update_eval_labels()
func clear_eval_labels():
	for i in range(g_eval_labels.size()):
		g_eval_labels[i].text = ""
func _on_print_eval_button_toggled(button_pressed):
	print("button_pressed = ", button_pressed)
	if button_pressed:
		print_eval_ix = 0
	else:
		clear_eval_labels()
	pass # Replace with function body.

func _on_rule_button_pressed():
	get_tree().change_scene_to_file("res://rule_scene.tscn")
	pass # Replace with function body.

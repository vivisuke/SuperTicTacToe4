extends Node2D

const N_VERT = 9
const N_HORZ = 9
const NEXT_LOCAL_BOARD = 0
#const MARU = 1
#const BATSU = 0
const WAIT = 6*3
const GVAL = 100
const SettingsFileName	= "user://KillerSudoku6_stgs.dat"

const g_pow_table = [	pow(3, 8), pow(3, 7), pow(3, 6),
						pow(3, 5), pow(3, 4), pow(3, 3),
						pow(3, 2), pow(3, 1), pow(3, 0), ]
const mb_str = ["Ｘ", "・", "Ｏ"]
enum {
	WHITE = -1, EMPTY, BLACK,				#	盤面石値、BLACK for 先手
	#TS_EMPTY = -1, TS_BATSU, TS_MARU,		#	タイルセットID
	TS_EMPTY = -1, TS_WHITE, TS_BLACK,		#	タイルセットID
	HUMAN = 0, AI_RANDOM, AI_DEPTH_1, AI_DEPTH_2, AI_DEPTH_3, AI_DEPTH_4, AI_DEPTH_5, 
	AI_PURE_MC,
	JA = 0, EN,			# 日本語/英語
}

class HistItem:
	var m_x:int				# 着手位置
	var m_y:int
	var m_linedup:bool		# 着手により、ローカルボード内で三目並んだ
	var m_next_board:int	# （着手前）着手可能ローカルボード [0, 9)
	func _init(px, py, lu, nb):
		m_x = px
		m_y = py
		m_linedup = lu
		m_next_board = nb
class Board:
	var m_nput = 0				# 総着手数
	var m_is_game_over			# 終局状態か？
	var m_winner				# 勝者（WHITE | EMPTY | BLACK)
	var m_next_board = -1		# 着手可能ローカルボード [0, 9)、-1 for 全ローカルボードに着手可能
	var m_next_color
	var m_linedup = false		# 直前の着手でローカルボード内で三目並んだ
	var m_lboard
	var m_gboard
	var m_nput_local = []		# 各ローカルボードの着手数
	var m_three_lined_up = []	# 各ローカルボード：三目並んだか？
	var m_bd_index = []			# 各ローカルボード盤面インデックス
	var m_gbd_index				# グローバルボード盤面インデックス
	var m_stack = []			# 要素：HistItem
	var m_eval_table			# 盤面インデックス→評価値テーブルへの参照
	var m_eval_count
	var m_rng = RandomNumberGenerator.new()
	func _init():
		#m_rng.randomize()		# Setups a time-based seed
		#m_rng.seed = 0			# 固定乱数系列
		init()
		#print(ev_put_table)
		pass
	func init():
		m_eval_count = 0
		m_nput = 0
		m_is_game_over = false
		m_winner = EMPTY
		m_next_color = BLACK
		m_nput_local = [0, 0, 0, 0, 0, 0, 0, 0, 0]
		m_three_lined_up = [false, false, false, false, false, false, false, false, false]
		m_bd_index = [0, 0, 0, 0, 0, 0, 0, 0, 0]
		m_gbd_index = 0
		m_next_board = -1
		m_lboard = []
		for ix in range(N_HORZ*N_VERT): m_lboard.push_back(EMPTY)
		m_gboard = []
		for ix in range(N_HORZ*N_VERT/9): m_gboard.push_back(EMPTY)
		m_stack = []
		pass
	func set_eval_table(eval_table): m_eval_table = eval_table
	func last_put_pos():
		if m_stack.is_empty(): return [-1, -1]
		else: return [m_stack.back().m_x, m_stack.back().m_y]
	func print():
		var txt = "   ａｂｃ　ｄｅｆ　ｇｈｉ\n"
		txt += " ＋－－－＋－－－＋－－－＋\n"
		for y in range(N_VERT):
			txt += "%d｜" % (y+1)
			for x in range(N_HORZ):
				if last_put_pos() != [x, y]:
					txt += ["●", "・", "○"][m_lboard[x + y*N_HORZ]+1]
					#txt += "X.O"[m_lboard[x + y*N_HORZ]+1]
				else:
					txt += ["◆", "・", "◇"][m_lboard[x + y*N_HORZ]+1]
					#txt += "#.C"[m_lboard[x + y*N_HORZ]+1]
				if x % 3 == 2: txt += "｜"
			txt += "\n"
			if y % 3 == 2: txt += " ＋－－－＋－－－＋－－－＋\n"
		txt += "\n"
		for y in range(N_VERT/3):
			for x in range(N_HORZ/3):
				txt += ["●", "・", "○"][m_gboard[x + y*(N_HORZ/3)]+1]
			txt += "\n"
		txt += "\n"
		# 各ローカルボード盤面石数表示
		txt += "nput[] = \n"
		for i in range(9):
			txt += "%d " % m_nput_local[i]
			if i % 3 == 2: txt += "\n";
		# 各ローカルボード盤面インデックス表示
		txt += "bd_index[] = \n"
		for i in range(9):
			txt += "%d " % m_bd_index[i]
			if i % 3 == 2: txt += "\n";
		txt += "%d\n" % m_gbd_index
		#
		if m_is_game_over:
			if m_winner == BLACK: txt += "O won.\n"
			elif m_winner == WHITE: txt += "X won.\n"
			else: txt += "draw.\n"
		else:
			txt += "next turn color: %s\n" % ("O" if m_next_color == BLACK else "X")
			txt += "next board = %d\n" % m_next_board
		txt += "last_put_pos = [%d, %d]\n" % last_put_pos()
		txt += "eval = %d\n" % eval_board_index()
		print(txt, "\n")
		#print("last_put_pos = ", last_put_pos())
		#print("eval = ", eval_board_index())
	func is_game_over(): return m_is_game_over
	func winner(): return m_winner
	func next_color(): return m_next_color
	func next_board(): return m_next_board
	func is_empty(x : int, y : int):			# ローカルボード内のセル状態取得
		return m_lboard[x + y*N_HORZ] == EMPTY
	func get_color(x : int, y : int):			# ローカルボード内のセル状態取得
		return m_lboard[x + y*N_HORZ]
	func get_gcolor(gx : int, gy : int):		# グローバルボード内のセル状態取得
		return m_gboard[gx + gy*(N_HORZ/3)]
	func update_next_board(x : int, y : int):	# 次に着手可能なローカルボード設定
		var x3 = x % 3
		var y3 = y % 3
		m_next_board = x3 + y3 * 3
		if m_three_lined_up[m_next_board] || m_nput_local[m_next_board] == 9:
			m_next_board = -1			# 全ローカルボードに着手可能
	func is_three_stones(x : int, y : int):		# 三目並んだか？
		var x3 : int = x % 3
		var x0 : int = x - x3		# ローカルボード内左端座標
		var y3 : int = y % 3
		var y0 : int = y - y3		# ローカルボード内上端座標
		if get_color(x0, y) == get_color(x0+1, y) && get_color(x0, y) == get_color(x0+2, y):
			return true;			# 横方向に三目並んだ
		if get_color(x, y0) == get_color(x, y0+1) && get_color(x, y0) == get_color(x, y0+2):
			return true;			# 縦方向に三目並んだ
		if x3 == y3:		# ＼斜め方向チェック
			if get_color(x0, y0) == get_color(x0+1, y0+1) && get_color(x0, y0) == get_color(x0+2, y0+2):
				return true;			# ＼斜め方向に三目並んだ
		if x3 == 2 - y3:		# ／斜め方向チェック
			if get_color(x0, y0+2) == get_color(x0+1, y0+1) && get_color(x0, y0+2) == get_color(x0+2, y0):
				return true;			# ／斜め方向に三目並んだ
	func is_three_stones_global(gx : int, gy : int):		# グローバルボードで三目並んだか？
		if get_gcolor(0, gy) == get_gcolor(1, gy) && get_gcolor(0, gy) == get_gcolor(2, gy):
			return true;			# 横方向に三目並んだ
		if get_gcolor(gx, 0) == get_gcolor(gx, 1) && get_gcolor(gx, 0) == get_gcolor(gx, 2):
			return true;			# 縦方向に三目並んだ
		if gx == gy:		# ＼斜め方向チェック
			if get_gcolor(0, 0) == get_gcolor(1, 1) && get_gcolor(0, 0) == get_gcolor(2, 2):
				return true;			# ＼斜め方向に三目並んだ
		if gx == 2 - gy:		# ／斜め方向チェック
			if get_gcolor(0, 2) == get_gcolor(1, 1) && get_gcolor(0, 2) == get_gcolor(2, 0):
				return true;			# ／斜め方向に三目並んだ
	func put(x : int, y : int, col):
		#last_put_pos = [x, y]
		m_linedup = false
		m_nput += 1					# トータル着手数
		m_lboard[x + y*N_HORZ] = col
		var gx = x / 3
		var gy = y / 3
		var ix = gx + gy*3
		var mx = x % 3;
		var my = y % 3;
		m_bd_index[ix] += g_pow_table[mx+my*3] * (1 if col==BLACK else 2);	#	盤面インデックス更新
		m_nput_local[ix] += 1		# 各ローカルボードの着手数
		#var linedup = false			# ローカルボード内で三目ならんだか？
		if !m_three_lined_up[ix] && is_three_stones(x, y):	# 三目並んだ→グローバルボード更新
			m_linedup = true
			m_gboard[ix] = col
			m_gbd_index += g_pow_table[ix] * (1 if col==BLACK else 2);	#	盤面インデックス更新
			m_three_lined_up[ix] = true
			if is_three_stones_global(gx, gy):
				m_is_game_over = true
				m_winner = col
		if !m_is_game_over && m_nput == N_HORZ*N_VERT:
			m_is_game_over = true
		m_stack.push_back(HistItem.new(x, y, m_linedup, m_next_board))
		m_next_color = (WHITE + BLACK) - col		# 手番交代
		update_next_board(x, y)					# next_board 設定
	func undo_put():
		if m_stack.is_empty(): return
		m_nput -= 1
		m_next_color = (WHITE + BLACK) - m_next_color	# 手番交代
		var itm = m_stack.pop_back()
		m_lboard[itm.m_x + itm.m_y*N_HORZ] = EMPTY
		var gx = itm.m_x / 3
		var gy = itm.m_y / 3
		var ix = gx + gy*3
		m_nput_local[ix] -= 1
		var mx = itm.m_x % 3;
		var my = itm.m_y % 3;
		m_bd_index[ix] -= g_pow_table[mx+my*3] * (1 if m_next_color==BLACK else 2);	#	盤面インデックス更新
		if itm.m_linedup:				# 着手で三目並んだ場合
			m_gboard[gx + gy*3] = EMPTY
			m_gbd_index -= g_pow_table[ix] * (1 if m_next_color==BLACK else 2);	#	盤面インデックス更新
			m_three_lined_up[ix] = false
			m_is_game_over = false
			m_winner = EMPTY
		m_next_board = itm.m_next_board
	func eval_board_index():	# 現局面を（○から見た）評価
		m_eval_count += 1
		#if( m_eval_count == 38 ):
		#	print("stoped for Debug.")
		var ev = 0
		if( is_game_over() ):
			ev = m_winner * GVAL * GVAL;
		else:
			for i in range(9):
				if !m_three_lined_up[i]:
					ev += m_eval_table[m_bd_index[i]]
			ev += m_eval_table[m_gbd_index] * GVAL
		#print(m_eval_count, ": ev = ", ev, ", m_next_board = ", m_next_board)
		return ev
	func select_random():
		if m_nput == 0:		# 初期状態
			return [m_rng.randi_range(0, N_HORZ-1), m_rng.randi_range(0, N_VERT-1)]
		elif m_next_board < 0:	# 全てのローカルボードに着手可能
			var lst = []
			for y in range(N_VERT):
				for x in range(N_HORZ):
					if is_empty(x, y): lst.push_back([x, y])
			return lst[m_rng.randi_range(0, lst.size() - 1)]
		else:
			var x0 = (m_next_board % 3) * 3
			var y0 = (m_next_board / 3) * 3
			var lst = []
			for v in range(3):
				for h in range(3):
					if is_empty(x0+h, y0+v):
						lst.push_back([x0+h, y0+v])
			return lst[m_rng.randi_range(0, lst.size() - 1)]
	func playout_random():
		var depth = 0
		while !is_game_over():
			var pos = select_random()
			put(pos[0], pos[1], next_color())
			depth += 1
		var winner = m_winner
		#self.print()
		for i in range(depth):
			undo_put()
		#self.print()
		return winner			# WHITE | EMPTY | BLACK
	func calc_win_rate(x, y, N) -> float:		# 次の手番の勝率を計算
		var bwon = 0
		var wwon = 0
		put(x, y, next_color())
		for i in range(N):
			var won = playout_random()
			if won != EMPTY:
				if won == BLACK: bwon += 1
				else: wwon += 1
		undo_put()
		if next_color() == BLACK:
			return float(bwon) / (bwon + wwon)
		else:
			return float(wwon) / (bwon + wwon)
	func select_pure_MC():
		pass
	func alpha_beta(alpha, beta, depth, ply):
		if depth <= 0 || is_game_over():
			#return eval_board_index()
			var ev = eval_board_index()
			if ev > 0: ev -= ply
			elif ev < 0: ev += ply
			return ev
		var x0
		var y0
		var NH = 3
		var NV = 3
		var D = 1
		if m_next_board < 0:		# 全ローカルボードに着手可能
			x0 = 0
			y0 = 0
			NH = N_HORZ
			NV = N_VERT
			D = 2
		else:
			x0 = (m_next_board % 3) * 3
			y0 = (m_next_board / 3) * 3
		for v in range(NV):
			for h in range(NH):
				if is_empty(x0+h, y0+v):
					put(x0+h, y0+v, m_next_color)
					var ev = alpha_beta(alpha, beta, depth-D, ply+1) #*0.9999
					undo_put()
					if m_next_color == BLACK:
						alpha = max(ev, alpha)
						if alpha >= beta:
							#print("*** beta cut, alpha = ", alpha)
							return alpha
					else:
						beta = min(ev, beta)
						if alpha >= beta:
							#print("*** alpha cut, beta = ", beta)
							return beta
		#print("alpha = ", alpha, ", beta = ", beta)
		if m_next_color == BLACK:
			#print("alpha = ", alpha)
			return alpha
		else:
			#print("beta = ", beta)
			return beta
	func select_alpha_beta(DEPTH):		# DEPTH先読み＋評価関数で着手決定
		#var bd = Board.new()
		m_eval_count = 0
		#bd.set_eval(g_eval)
		#bd.copy(self)
		#var DEPTH = 3
		if DEPTH > 2:
			if m_nput >= 9*2: DEPTH += 1
			if m_nput >= 9*4: DEPTH += 1
			if m_nput >= 9*6: DEPTH += 1
		var ps;
		var alpha = -99999
		var beta = 99999
		var x0
		var y0
		var NH = 3
		var NV = 3
		var D = 1
		if m_next_board < 0:		# 全ローカルボードに着手可能
			x0 = 0
			y0 = 0
			NH = N_HORZ
			NV = N_VERT
			D = 2
		else:
			x0 = (m_next_board % 3) * 3
			y0 = (m_next_board / 3) * 3
		var lst = []
		for v in range(NV):
			for h in range(NH):
				if is_empty(x0+h, y0+v):
					put(x0+h, y0+v, m_next_color)
					var ev = alpha_beta(alpha, beta, DEPTH-D, 0) #*0.9999
					undo_put()
					if m_next_color == BLACK:
						if ev > alpha:
							alpha = ev
							ps = [x0+h, y0+v]
							if DEPTH <= 2: lst = [ps]
						elif ev == alpha && DEPTH <= 2:
							lst.push_back([x0+h, y0+v])
					else:
						if ev < beta:
							beta = ev
							ps = [x0+h, y0+v]
							if DEPTH <= 2: lst = [ps]
						elif ev == beta && DEPTH <= 2:
							lst.push_back([x0+h, y0+v])
		if !lst.is_empty():
			ps = lst[m_rng.randi_range(0, lst.size()-1)]
		print("m_eval_count = ", m_eval_count)
		print("eval = ", (alpha if m_next_color == BLACK else beta))
		print("winner = ", m_winner)
		return ps

#----------------------------------------------------------------------

const LINED3 = 100;				#	3目並んだ
const LINED2 = 8;				#	2目並んだ
const LINED1 = 1;				#	1目のみ

var lang = JA
var settings = {}		# 設定辞書

var white_player = HUMAN
var black_player = HUMAN
var bd			# 盤面オブジェクト
var g_board3x3 = []			# 3x3 盤面 for 作業用
var g_eval_table = []		# 盤面インデックス→評価値 テーブル
var rng = RandomNumberGenerator.new()

func _ready():
	print("Global._ready()")
	rng.randomize()		# Setups a time-based seed
	#rng.seed = 0		# 固定乱数系列
	load_lang()
	bd = Board.new()
	bd.m_rng = rng
	bd.set_eval_table(g_eval_table)
	build_3x3_eval_table()			# 3x3盤面→評価値テーブル構築
	bd.init()
	pass # Replace with function body.

func eval3(c1, c2, c3):		# 石の値は 0 for 空欄、±1 for 白・黒 と仮定
	var sum = c1 + c2 + c3;
	if( sum == BLACK * 3 ): return LINED3;
	if( sum == WHITE * 3 ): return -LINED3;
	if( sum == BLACK * 2 ): return LINED2;
	if( sum == WHITE * 2 ): return -LINED2;
	var n = c1*c1 + c2*c2 + c3*c3;		#	置かれた石数
	if( n == 1 ):
		if( sum == BLACK ): return LINED1;
		if( sum == WHITE ): return -LINED1;
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
			1:	g_board3x3[i] = BLACK
			2:	g_board3x3[i] = WHITE
		index /= 3
		i -= 1
func build_3x3_eval_table():
	g_board3x3.resize(3*3)
	g_eval_table.resize(pow(3, 9))		# 3^9
	for ix in range(g_eval_table.size()):
		set_board3x3(ix);
		g_eval_table[ix] = eval3x3(g_board3x3);
		#print(g_eval_table[ix]);

#
func load_lang():
	#var file = FileAccess.new()
	if FileAccess.file_exists(SettingsFileName):		# 設定ファイル
		var file = FileAccess.open(SettingsFileName, FileAccess.READ)
		lang = file.get_var()
		file.close()
func save_lang():
	#var file = File.new()
	var file = FileAccess.open(SettingsFileName, FileAccess.WRITE)
	file.store_var(lang)
	file.close()

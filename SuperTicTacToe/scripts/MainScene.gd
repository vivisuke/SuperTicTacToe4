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
	TS_EMPTY = -1, TS_BATSU, TS_MARU,		#	タイルセットID
	HUMAN = 0, AI_RANDOM, AI_DEPTH_1, AI_DEPTH_3,
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
	var m_nput = 0				# 着手数
	var m_is_game_over			# 終局状態か？
	var m_winner				# 勝者
	var m_next_board = -1		# 着手可能ローカルボード [0, 9)、-1 for 全ローカルボードに着手可能
	var m_next_color
	var m_lboard
	var m_gboard
	var m_nput_local = []		# 各ローカルボードの着手数
	var m_three_lined_up = []	# 各ローカルボード：三目並んだか？
	var m_bd_index = []			# 各ローカルボード盤面インデックス
	var m_gbd_index				# グローバルボード盤面インデックス
	var m_stack = []			# 要素：HistItem
	var m_r_eval				# 盤面インデックス→評価値テーブルへの参照
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
		m_next_color = WHITE
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
		#
		for i in range(9):
			txt += "%d " % m_bd_index[i]
			if i % 3 == 2: txt += "\n";
		txt += "%d\n" % m_gbd_index
		#
		if m_is_game_over:
			if m_winner == WHITE: txt += "O won.\n"
			elif m_winner == BLACK: txt += "X won.\n"
			else: txt += "draw.\n"
		else:
			txt += "next turn color: %s\n" % ("O" if m_next_color == WHITE else "X")
			txt += "next board = %d\n" % m_next_board
		txt += "last_put_pos = [%d, %d]\n" % last_put_pos()
		print(txt)
		#print("last_put_pos = ", last_put_pos())
		#print("eval = ", eval_board_index())
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
		m_nput += 1					# トータル着手数
		m_lboard[x + y*N_HORZ] = col
		var gx = x / 3
		var gy = y / 3
		var ix = gx + gy*3
		var mx = x % 3;
		var my = y % 3;
		m_bd_index[ix] += g_pow_table[mx+my*3] * (1 if col==WHITE else 2);	#	盤面インデックス更新
		m_nput_local[ix] += 1		# 各ローカルボードの着手数
		var linedup = false			# ローカルボード内で三目ならんだか？
		if !m_three_lined_up[ix] && is_three_stones(x, y):	# 三目並んだ→グローバルボード更新
			linedup = true
			m_gboard[ix] = col
			m_gbd_index += g_pow_table[ix] * (1 if col==WHITE else 2);	#	盤面インデックス更新
			m_three_lined_up[ix] = true
			if is_three_stones_global(gx, gy):
				m_is_game_over = true
				m_winner = col
		if !m_is_game_over && m_nput == N_HORZ*N_VERT:
			m_is_game_over = true
		m_stack.push_back(HistItem.new(x, y, linedup, m_next_board))
		m_next_color = (WHITE + BLACK) - col		# 手番交代
		update_next_board(x, y)					# next_board 設定
	func undo_put():
		if m_stack.is_empty(): return
		m_next_color = (WHITE + BLACK) - m_next_color	# 手番交代
		var itm = m_stack.pop_back()
		m_lboard[itm.m_x + itm.m_y*N_HORZ] = EMPTY
		var gx = itm.m_x / 3
		var gy = itm.m_y / 3
		var ix = gx + gy*3
		m_nput_local[ix] -= 1
		var mx = itm.m_x % 3;
		var my = itm.m_y % 3;
		m_bd_index[ix] -= g_pow_table[mx+my*3] * (1 if m_next_color==WHITE else 2);	#	盤面インデックス更新
		if itm.m_linedup:				# 着手で三目並んだ場合
			m_gboard[gx + gy*3] = EMPTY
			m_gbd_index -= g_pow_table[ix] * (1 if m_next_color==WHITE else 2);	#	盤面インデックス更新
			m_is_game_over = false
		m_next_board = itm.m_next_board

#----------------------------------------------------------------------

var g_bd			# 盤面オブジェクト
var rng = RandomNumberGenerator.new()

func _ready():
	rng.randomize()		# Setups a time-based seed
	#rng.seed = 0		# 固定乱数系列
	g_bd = Board.new()
	g_bd.m_rng = rng
	g_bd.print()
	g_bd.put(0, 0, WHITE)
	g_bd.print()
	g_bd.undo_put()
	g_bd.print()
	printraw("foo")
	printraw("bar\n")
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

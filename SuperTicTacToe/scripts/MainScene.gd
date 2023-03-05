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
	var m_n_put = 0				# 着手数
	var m_is_game_over			# 終局状態か？
	var m_winner				# 勝者
	var m_next_board = -1		# 着手可能ローカルボード [0, 9)、-1 for 全ローカルボードに着手可能
	var m_next_color
	var m_l_board
	var m_g_board
	var m_n_put_local = []		# 各ローカルボードの着手数
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
		m_n_put = 0
		m_is_game_over = false
		m_winner = EMPTY
		m_next_color = WHITE
		m_n_put_local = [0, 0, 0, 0, 0, 0, 0, 0, 0]
		m_three_lined_up = [false, false, false, false, false, false, false, false, false]
		m_bd_index = [0, 0, 0, 0, 0, 0, 0, 0, 0]
		m_gbd_index = 0
		m_next_board = -1
		m_l_board = []
		for ix in range(N_HORZ*N_VERT): m_l_board.push_back(EMPTY)
		m_g_board = []
		for ix in range(N_HORZ*N_VERT/9): m_g_board.push_back(EMPTY)
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
					txt += ["●", "・", "○"][m_l_board[x + y*N_HORZ]+1]
					#txt += "X.O"[m_l_board[x + y*N_HORZ]+1]
				else:
					txt += ["◆", "・", "◇"][m_l_board[x + y*N_HORZ]+1]
					#txt += "#.C"[m_l_board[x + y*N_HORZ]+1]
				if x % 3 == 2: txt += "｜"
			txt += "\n"
			if y % 3 == 2: txt += " ＋－－－＋－－－＋－－－＋\n"
		txt += "\n"
		for y in range(N_VERT/3):
			for x in range(N_HORZ/3):
				txt += ["●", "・", "○"][m_g_board[x + y*(N_HORZ/3)]+1]
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

#----------------------------------------------------------------------

var g_bd			# 盤面オブジェクト
var rng = RandomNumberGenerator.new()

func _ready():
	rng.randomize()		# Setups a time-based seed
	#rng.seed = 0		# 固定乱数系列
	g_bd = Board.new()
	g_bd.m_rng = rng
	g_bd.print()
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

extends Node2D

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
	var m_g_eval_count
	var m_rng = RandomNumberGenerator.new()
	func _init():
		#m_rng.randomize()		# Setups a time-based seed
		#m_rng.seed = 0			# 固定乱数系列
		init()
		#print(ev_put_table)
		pass
	func init():
		pass
	pass

#----------------------------------------------------------------------

var g_bd			# 盤面オブジェクト
var rng = RandomNumberGenerator.new()

func _ready():
	rng.randomize()		# Setups a time-based seed
	#rng.seed = 0		# 固定乱数系列
	g_bd = Board.new()
	g_bd.m_rng = rng
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

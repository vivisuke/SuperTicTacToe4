extends Node2D

var page = 0;			# 
var pict = []
var page_buttons = []

var rule_text = [
	"Super Tic-Tac-Toe (超三目並べ) は, 小さい盤面 (ローカルボード) に ○, ☓ を交互に打っていき, 大きい盤面 (グローバルボード) で先に三目並びを作った方が勝ちのゲームです。",
	"ローカルボードで ○ (☓) 三目並びを作ると, グローバルボードの対応するセルに大きい ○ (☓) が置かれます。",
	"ローカルボード内に打った箇所により, 次に着手可能なローカルボード (背景が白) が決まります。",
	"ただし次がすでに三目並んでいる, または空きが無い場合は, 全ての箇所に打つことが可能です。",
]

# Called when the node enters the scene tree for the first time.
func _ready():
	pict = [ $BGRect/SpriteWhiteWon, $BGRect/SpriteMake3, $BGRect/SpriteNextBoard, $BGRect/SpriteNextBoardAll, ]
	#pict.resize(rule_text.size())
	#pict[0] = get_node("SpriteWhiteWon")
	page_buttons = [ $HBC/Page1Button, $HBC/Page2Button, $HBC/Page3Button, $HBC/Page4Button, ]
	update_pict_text_buttons()
	pass # Replace with function body.

func update_pict_text_buttons():
	$PageLabel.text = "%d/%d" % [page+1, pict.size()]
	for i in pict.size():
		if i == page:
			pict[i].show()
		else:
			pict[i].hide()
		#pict[i].visible = i == page
		page_buttons[i].button_pressed = i == page
	$RuleLabel.text = rule_text[page]
	$HBC/PrevButton.disabled = page == 0
	$HBC/NextButton.disabled = page == rule_text.size() - 1
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
func _on_back_button_pressed():
	get_tree().change_scene_to_file("res://main_scene.tscn")
	pass # Replace with function body.
func _on_prev_button_pressed():
	if page != 0:
		page -= 1
		update_pict_text_buttons()
	pass # Replace with function body.
func _on_next_button_pressed():
	if page != rule_text.size() - 1:
		page += 1
		update_pict_text_buttons()
	pass # Replace with function body.
func _on_page1_button_pressed():
	page = 0
	update_pict_text_buttons()
	pass # Replace with function body.
func _on_page2_button_pressed():
	page = 1
	update_pict_text_buttons()
	pass # Replace with function body.
func _on_page3_button_pressed():
	page = 2
	update_pict_text_buttons()
	pass # Replace with function body.
func _on_page4_button_pressed():
	page = 3
	update_pict_text_buttons()
	pass # Replace with function body.

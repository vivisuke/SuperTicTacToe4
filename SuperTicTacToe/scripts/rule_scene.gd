extends Node2D

var page = 0;			# 
var pict = []

var rule_text = [
	"Super Tic-Tac-Toe（超三目並べ）は, 小さい盤面（ローカルボード）に○☓ を交互に打っていき, 大きい盤面（グローバルボード）で先に三目並びを作った方が勝ちのゲームです。",
	"ローカルボードで○（☓）三目並びを作ると, グローバルボードの対応するセルに大きい○（☓）が置かれます。",
	"ローカルボード内に打った箇所により, 次に着手可能なローカルボード（背景が白）が決まります。" +
	"ただし次がすでに三目並んでいる, または空きが無い場合は, 全ての箇所に打つことが可能です。",
]

# Called when the node enters the scene tree for the first time.
func _ready():
	pict = [ $BGRect/SpriteWhiteWon, $BGRect/SpriteMake3, $BGRect/SpriteNextBoard, ]
	#pict.resize(rule_text.size())
	#pict[0] = get_node("SpriteWhiteWon")
	update_pict_text_buttons()
	pass # Replace with function body.

func update_pict_text_buttons():
	for i in pict.size():
		if i == page:
			pict[i].show()
		else:
			pict[i].hide()
		#pict[i].visible = i == page
	$RuleLabel.text = rule_text[page]
	$PrevButton.disabled = page == 0
	$NextButton.disabled = page == rule_text.size() - 1
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

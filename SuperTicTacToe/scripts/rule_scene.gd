extends Node2D


var rule_text = [
	"Super Tic-Tac-Toe（超三目並べ）は、小さい盤面（ローカルボード）に○☓ を交互に打っていき、大きい盤面（グローバルボード）で先に三目並べた方が勝ちのゲームです。",
	"ローカルボードで○（☓）三目並びを作ると、グローバルボードの対応するセルに大きい○（☓）が置かれます。",
	"ローカルボード内に打った箇所により、次に着手可能なローカルボード（背景が白）が決まります。",
]

# Called when the node enters the scene tree for the first time.
func _ready():
	$RuleLabel.text = rule_text[2]
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_back_button_pressed():
	get_tree().change_scene_to_file("res://main_scene.tscn")
	pass # Replace with function body.

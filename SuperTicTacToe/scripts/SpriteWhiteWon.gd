extends Sprite2D


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _draw():
	var style_box = StyleBoxFlat.new()      # 影、ボーダなどを描画するための矩形スタイルオブジェクト
	style_box.bg_color = Color.TRANSPARENT   # 矩形背景色
	style_box.shadow_offset = Vector2(0, 4)     # 影オフセット
	style_box.shadow_size = 8                   # 影（ぼかし）サイズ
	draw_style_box(style_box, Rect2(Vector2(-250, -250), Vector2(500, 500)))      # style_box に設定した矩形を描画
	pass

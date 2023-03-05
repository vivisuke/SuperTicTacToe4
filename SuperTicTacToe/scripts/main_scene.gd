extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready():
	#printraw("_ready \n")
	print("OK")
	#$Board/TileMapLocal.erase_cell(0, Vector2i(3, 0))
	$Board/TileMapLocal.set_cell(0, Vector2i(3, 0), 1, Vector2i(0, 0))
	print("(0, 0) = ", $Board/TileMapLocal.get_cell_source_id (0, Vector2i(0, 0)))
	$Board/TileMapLocal.set_cell(0, Vector2i(0, 0), 1)
	print("(0, 0) = ", $Board/TileMapLocal.get_cell_source_id (0, Vector2i(0, 0)))
	print("(3, 0) = ", $Board/TileMapLocal.get_cell_source_id (0, Vector2i(3, 0)))
	print("(4, 1) = ", $Board/TileMapLocal.get_cell_source_id (0, Vector2i(4, 1)))
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_start_stop_button_pressed():
	print("_on_start_stop_button_pressed()\n")
	print("(0, 0) = ", $Board/TileMapBG.get_cell_source_id (0, Vector2i(0, 0)))
	$Board/TileMapBG.set_cell(0, Vector2i(0, 0), 0)
	print("(0, 0) = ", $Board/TileMapBG.get_cell_source_id (0, Vector2i(0, 0)))
	print("(1, 1) = ", $Board/TileMapBG.get_cell_source_id (0, Vector2i(1, 1)))
	pass # Replace with function body.

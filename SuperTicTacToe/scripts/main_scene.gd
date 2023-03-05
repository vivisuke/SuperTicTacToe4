extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready():
	printraw("_ready \n")
	print("OK")
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_start_stop_button_pressed():
	print("_on_start_stop_button_pressed()\n")
	pass # Replace with function body.

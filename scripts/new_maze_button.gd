extends Button


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.pressed.connect(_on_click)


func _on_click():
	var loop_slider_value = get_node("../LoopSlider").value
	var maze_layer = get_node("/root/Node2D/MazeLayer")
	maze_layer.maze_seed = randi()
	maze_layer.make_maze(loop_slider_value, false)

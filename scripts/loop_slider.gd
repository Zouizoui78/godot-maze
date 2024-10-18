extends HSlider


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.value_changed.connect(self._update_maze)


func _update_maze(value_changed: bool) -> void:
	var maze_layer = get_node("/root/Node2D/MazeLayer")
	maze_layer.make_maze(self.value, false)

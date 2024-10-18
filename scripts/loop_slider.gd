extends HSlider


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.value_changed.connect(self._update_maze)


func _update_maze(_new_value: float) -> void:
	get_node("/root/Node2D/MazeLayer").make_maze()

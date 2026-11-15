class_name PieceData
extends RefCounted
## One block piece: a set of cells (x, y), normalised so the minimum is 0, 0.

var shape: Array[Vector2i] = []
var color_id: int = 1
var width: int = 1
var height: int = 1


func _init(p_shape: Array[Vector2i] = [], p_color_id: int = 1) -> void:
	shape = p_shape
	color_id = p_color_id
	for cell: Vector2i in shape:
		width = maxi(width, cell.x + 1)
		height = maxi(height, cell.y + 1)


func cell_count() -> int:
	return shape.size()

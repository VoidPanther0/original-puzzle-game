class_name PieceDefs
extends RefCounted
## The catalogue of piece shapes. Shapes are written as small text maps and
## every distinct rotation is added to the pool.

const COLOR_COUNT: int = 7

const BASE_SHAPES: Array[String] = [
	"X",
	"XX",
	"XXX",
	"XXXX",
	"XXXXX",
	"XX/XX",
	"XXX/XXX/XXX",
	"X./XX",
	"X../X../XXX",
	"XXX/.X.",
	".XX/XX.",
	"XX/.XX",
	"XXX/X..",
	"XX/X./X.",
]

static var _pool: Array = []  # Array of Array[Vector2i]


## Parses a text map such as "XX/X." into cells. "/" separates rows.
static func parse(text: String) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var rows: PackedStringArray = text.split("/")
	for y: int in rows.size():
		for x: int in rows[y].length():
			if rows[y][x] == "X":
				cells.append(Vector2i(x, y))
	return cells


static func _normalize(cells: Array[Vector2i]) -> Array[Vector2i]:
	var min_x: int = 1000
	var min_y: int = 1000
	for c: Vector2i in cells:
		min_x = mini(min_x, c.x)
		min_y = mini(min_y, c.y)
	var out: Array[Vector2i] = []
	for c: Vector2i in cells:
		out.append(Vector2i(c.x - min_x, c.y - min_y))
	out.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return a.y < b.y or (a.y == b.y and a.x < b.x))
	return out


static func _rotate(cells: Array[Vector2i]) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for c: Vector2i in cells:
		out.append(Vector2i(-c.y, c.x))
	return _normalize(out)


## All distinct oriented shapes. Built once and cached.
static func pool() -> Array:
	if not _pool.is_empty():
		return _pool
	var seen: Dictionary = {}
	for text: String in BASE_SHAPES:
		var current: Array[Vector2i] = _normalize(parse(text))
		for _i: int in 4:
			var key: String = str(current)
			if not seen.has(key):
				seen[key] = true
				_pool.append(current)
			current = _rotate(current)
	return _pool

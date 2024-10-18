extends TileMapLayer

const N = 1
const E = 2
const S = 4
const W = 8

const cell_walls = {
	Vector2i(1, 0): E,
	Vector2i(-1, 0): W,
	Vector2i(0, 1): S,
	Vector2i(0, -1): N
}

var tile_size: Vector2i = tile_set.tile_size
var width = 30
var height = 20

var maze_seed = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	maze_seed = randi()

	var args = Array(OS.get_cmdline_args())

	var demo = args.any(func(arg): return arg in ["-t", "--tileset"])
	if demo:
		show_tileset()
		return

	var slow_mode = args.any(func(arg): return arg in ["-s", "--slow-mode"])

	make_maze(0, false)

	# changement de la taille de la fenêtre pour qu'elle puisse afficher toutes les tuiles
	get_window().size = Vector2i(width * tile_size[0], height * tile_size[1])


func show_tileset() -> void:
	width = 4
	height = 4
	for h in range(height):
		for w in range(width):
			set_cell(Vector2i(w, h), 0, wall_mask_to_atlas_coords(h * 4 + w))


func list_unvisited_neighbors(cell: Vector2i, unvisited: Array[Vector2i]) -> Array[Vector2i]:
	# returns an array of cell's unvisited neighbors
	var list: Array[Vector2i] = []

	for n in cell_walls.keys():
		if cell + n in unvisited:
			list.append(cell + n)

	return list


# Show grass on each tile and return an array of coordinates of the tiles
func clear_maze() -> Array[Vector2i]:
	clear()

	var grass_atlas_coords = wall_mask_to_atlas_coords(W|S|E|N)
	var unvisited: Array[Vector2i]

	# fill the map with solid tiles
	for x in range(width):
		for y in range(height):
			unvisited.append(Vector2i(x, y))
			set_cell(Vector2i(x, y), 0, grass_atlas_coords)

	return unvisited


func make_maze(loop_fraction: float = 0, slow_mode: bool = false) -> void:
	seed(maze_seed)

	var stack = []
	var current = Vector2i(0, 0)
	var unvisited = clear_maze()

	unvisited.erase(current)

	# execute recursive backtracker algorithm
	while unvisited:
		var neighbors = list_unvisited_neighbors(current, unvisited)
		if neighbors.size() > 0:
			var next = neighbors[randi() % neighbors.size()]
			stack.append(current)

			# calcul la direction de la case actuelle vers la prochaine case
			var direction = next - current

			# récupère le wall_mask (= id) de la tuile courante et de la suivante
			var current_wall_mask = cell_coords_to_wall_mask(current)
			var next_wall_mask = cell_coords_to_wall_mask(next)

			# on "supprime" le bon mur (celui se trouvant entre current et next)
			# de la case actuelle et de la suivante
			var current_new_wall_mask = current_wall_mask - cell_walls[direction]
			var next_new_wall_mask = next_wall_mask - cell_walls[-direction]

			# enfin on affiche les bonnes tuiles dans les cases current et next
			set_cell(current, 0, wall_mask_to_atlas_coords(current_new_wall_mask))
			set_cell(next, 0, wall_mask_to_atlas_coords(next_new_wall_mask))

			current = next
			unvisited.erase(current)
		elif stack:
			current = stack.pop_back()

		if slow_mode:
			# attend le début du processing de la prochaine frame
			# autrement dit on met à jour le labyrinthe une fois par frame
			# donc 30 fois/secondes si on est à 30fps par exemple
			await get_tree().process_frame

	if loop_fraction > 0:
		make_loops(loop_fraction)


func make_loops(loop_fraction: float):
	loop_fraction = clampf(loop_fraction, 0 , 1)
	var cell_border_margin = 2

	for i in range(int(width * height * loop_fraction)):
		var cell_x = randi_range(cell_border_margin, width - cell_border_margin)
		var cell_y = randi_range(cell_border_margin, height - cell_border_margin)
		var cell = Vector2i(cell_x, cell_y)
		var neighbor = cell_walls.keys()[randi() % cell_walls.size()]

		var cell_wall_mask = cell_coords_to_wall_mask(cell)
		var neighbor_wall_mask = cell_coords_to_wall_mask(cell + neighbor)

		# if there's a wall between cell and neighbor
		if cell_wall_mask & cell_walls[neighbor]:
			var new_cell_wall = cell_wall_mask - cell_walls[neighbor]
			var new_neighbor_wall_mask = neighbor_wall_mask - cell_walls[-neighbor]

			set_cell(cell, 0, wall_mask_to_atlas_coords(new_cell_wall))
			set_cell(cell + neighbor, 0, wall_mask_to_atlas_coords(new_neighbor_wall_mask))


func wall_mask_to_atlas_coords(wall_mask: int) -> Vector2i:
	match wall_mask:
		0:
			return Vector2i(9, 0)
		N: # 1
			return Vector2i(5, 3)
		E: # 2
			return Vector2i(5, 2)
		N | E: # 3
			return Vector2i(2, 0)
		S: # 4
			return Vector2i(4, 3)
		S | N: # 5
			return Vector2i(0, 1)
		S | E: # 6
			return Vector2i(2, 1)
		S | E | N: # 7
			return Vector2i(9, 3)
		W: # 8
			return Vector2i(4, 2)
		W | N: # 9
			return Vector2i(1,0)
		W | E: # 10
			return Vector2i(0, 0)
		W | E | N: # 11
			return Vector2i(8, 2)
		W | S: # 12
			return Vector2i(1, 1)
		W | S | N: # 13
			return Vector2i(8, 3)
		W | S | E: # 14
			return Vector2i(9, 2)
		_: # 15 or default, show grass
			return Vector2i(0, 2)


func atlas_coords_to_wall_mask(atlas_coords: Vector2i) -> int:
	match atlas_coords:
		Vector2i(9, 0):
			return 0
		Vector2i(5, 3):
			return N # 1
		Vector2i(5, 2):
			return E # 2
		Vector2i(2, 0):
			return N | E # 3
		Vector2i(4, 3):
			return S # 4
		Vector2i(0, 1):
			return S | N # 5
		Vector2i(2, 1):
			return S | E # 6
		Vector2i(9, 3):
			return S | E | N # 7
		Vector2i(4, 2):
			return W # 8
		Vector2i(1,0):
			return W | N # 9
		Vector2i(0, 0):
			return W | E # 10
		Vector2i(8, 2):
			return W | E | N # 11
		Vector2i(1, 1):
			return W | S # 12
		Vector2i(8, 3):
			return W | S | N # 13
		Vector2i(9, 2):
			return W | S | E # 14
		_:
			return W | S | E | N


func cell_coords_to_wall_mask(cell_coords: Vector2i) -> int:
	return atlas_coords_to_wall_mask(get_cell_atlas_coords(cell_coords))

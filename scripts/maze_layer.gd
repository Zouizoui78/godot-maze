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

var tile_size = tile_set.tile_size
var width = 30
var height = 20

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# changement de la taille de la fenêtre pour qu'elle puisse afficher toutes les tuiles
	get_window().size = Vector2i(width * tile_size[0], height * tile_size[1])

	#show_tileset() # commente make_maze() si tu décommentes ça

	var args = Array(OS.get_cmdline_args())
	var slow_mode = args.has("-s")
	make_maze(slow_mode) # passe true en argument pour voir le labyrinthe se construire
	
func show_tileset() -> void:
	width = 4
	height = 4
	for h in range(height):
		for w in range(width):
			set_cell(Vector2i(w, h), 0, wall_mask_to_atlas_coords(h * 4 + w))
	
	
func list_unvisited_neighbors(cell, unvisited):
	# returns an array of cell's unvisited neighbors
	var list = []
	for n in cell_walls.keys():
		if cell + n in unvisited:
			list.append(cell + n)
	return list
	
func make_maze(slow_mode: bool = false):
	var unvisited = []  # array of unvisited tiles
	var stack = []
	var current = Vector2i(0, 0)

	# fill the map with solid tiles
	clear()
	var grass_atlas_coords = wall_mask_to_atlas_coords(W|S|E|N)
	for x in range(width):
		for y in range(height):
			unvisited.append(Vector2i(x, y))
			set_cell(Vector2i(x, y), 0, grass_atlas_coords)
	
	unvisited.erase(current)

	# execute recursive backtracker algorithm
	while unvisited:
		var neighbors = list_unvisited_neighbors(current, unvisited)
		if neighbors.size() > 0:
			var next = neighbors[randi() % neighbors.size()]
			stack.append(current)

			# calcul la direction de la case actuelle vers la prochaine case
			var direction = next - current
			
			# récupère les coordonnées de la tuile actuelle dans le tileset
			var current_coords = get_cell_atlas_coords(current)
			
			# récupère le wall_mask (= id) de la tuile depuis ses coordonnées dans le tileset
			var current_wall_mask = atlas_coords_to_wall_mask(current_coords)
			
			# même chose pour la case suivante
			var next_coords = get_cell_atlas_coords(next)
			var next_wall_mask = atlas_coords_to_wall_mask(next_coords)

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

func wall_mask_to_atlas_coords(wall_mask) -> Vector2i:
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

func atlas_coords_to_wall_mask(atlas_coords) -> int:
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


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

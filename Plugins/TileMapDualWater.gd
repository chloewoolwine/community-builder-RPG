@tool
class_name TileMapDualWater
extends TileMapDual

## Coordinates for the fully-filled tile in the Atlas
## that will be used to sketch in the World grid.
## Defaults to the one in the standard Godot template.
## Only this tile will be considered for autotiling.
## The opposed of full_tile.
## Used in-game to erase sketched tiles. 

func _ready() -> void:
	## These are inverted for water tiles 
	full_tile = Vector2i(0,3)
	empty_tile = Vector2i(2,1)
	if freeze:
		return
	
	if debug:
		print('Updating in-game is activated')
	
	if world_tilemap == null:
		if self.owner.is_class('TileMapDual'):
			world_tilemap = self.owner
	update_tileset()

func update_tileset() -> void:
	if freeze:
		return
	
	self.position.x = - self.tile_set.tile_size.x * 0.5
	self.position.y = - self.tile_set.tile_size.y * 0.5
	_update_tiles()


## Update all displayed tiles from the dual grid.
## It will only process fully-filled tiles from the world grid.
func _update_tiles() -> void:
	if debug:
		print('Updating tiles....................')
	
	self.clear()
	checked_cells = [true]
	for _world_cell in world_tilemap.get_used_cells():
		if _is_world_tile_sketched(_world_cell):
			print('Updating:.', _world_cell)
			update_tile(_world_cell)
	# checked_cells will only be used when updating
	# the entire tilemap to avoid repeating checks.
	# This check is skipped when updating tiles individually.
	checked_cells = [false]

## Takes a world cell, and updates the
## overlapping tiles from the dual grid accordingly.
func update_tile(world_cell: Vector2i) -> void:
	if freeze:
		return
	
	if debug:
		print('  Updating displayed cells around world cell ' + str(world_cell) + '...')
	
	# Calculate the overlapping cells from the dual grid and update them accordingly
	var _top_left: Vector2i = world_cell + NEIGHBOURS[location.TOP_LEFT]
	var _low_left: Vector2i = world_cell + NEIGHBOURS[location.LOW_LEFT]
	var _top_right: Vector2i = world_cell + NEIGHBOURS[location.TOP_RIGHT]
	var _low_right: Vector2i = world_cell + NEIGHBOURS[location.LOW_RIGHT]
	_update_displayed_tile(_top_left)
	_update_displayed_tile(_low_left)
	_update_displayed_tile(_top_right)
	_update_displayed_tile(_low_right)


func _update_displayed_tile(_display_cell: Vector2i) -> void:
	# Avoid updating cells more than necessary
	if checked_cells[0] == true:
		if _display_cell in checked_cells:
			return
		checked_cells.append(_display_cell)
	
	if debug:
		print('    Checking display tile ' + str(_display_cell) + '...')
	
	# INFO: To get the world cells from the dual grid, we apply the opposite vectors
	var _top_left: Vector2i = _display_cell - NEIGHBOURS[location.LOW_RIGHT]  # - (1,1)
	var _low_left: Vector2i = _display_cell - NEIGHBOURS[location.TOP_RIGHT]  # - (1,0)
	var _top_right: Vector2i = _display_cell - NEIGHBOURS[location.LOW_LEFT]  # - (0,1)
	var _low_right: Vector2i = _display_cell - NEIGHBOURS[location.TOP_LEFT]  # - (0,0)
	
	# We perform a bitwise summation over the sketched neighbours
	var _tile_key: int = 0
	if _is_world_tile_sketched(_top_left):
		_tile_key += location.TOP_LEFT
	if _is_world_tile_sketched(_low_left):
		_tile_key += location.LOW_LEFT
	if _is_world_tile_sketched(_top_right):
		_tile_key += location.TOP_RIGHT
	if _is_world_tile_sketched(_low_right):
		_tile_key += location.LOW_RIGHT
	
	var _coords_atlas: Vector2i = WET_NEIGHBOURS_TO_ATLAS[_tile_key]
	self.set_cell(_display_cell, 0, _coords_atlas)
	if debug:
		print('    Display tile ' + str(_display_cell) + ' updated with key ' + str(_tile_key))


func _is_world_tile_sketched(_world_cell: Vector2i) -> bool:
	var _atlas_coords: Vector2i = world_tilemap.get_cell_atlas_coords(_world_cell)
	if _atlas_coords == full_tile:
		if debug:
			print('      World cell ' + str(_world_cell) + ' IS sketched with atlas coords ' + str(_atlas_coords))
		return true
	else:
		# If the cell is empty, get_cell_atlas_coords() returns (-1,-1)
		if Vector2(_atlas_coords) == Vector2(-1,-1):
			if debug:
				print('      World cell ' + str(_world_cell) + ' Is EMPTY')
			return false
		if debug:
			print('      World cell ' + str(_world_cell) + ' Is NOT sketched with atlas coords ' + str(_atlas_coords))
		return false

## Public method to add a tile in a given World cell
func fill_tile(world_cell: Vector2i, source_id: int = 0) -> void:
	if freeze:
		return
	if debug:
		print(' setting cell: ', world_cell)
	world_tilemap.set_cell(world_cell, world_source_id, full_tile)
	if debug:
		print(" empty tile: ", empty_tile, "  full tile: ", full_tile)
	update_tile(world_cell)


## Public method to erase a tile in a given World cell
func erase_tile(world_cell: Vector2i) -> void:
	if freeze:
		return
	world_tilemap.set_cell(world_cell, world_source_id, empty_tile)
	update_tile(world_cell)
	
	
## Erases a tile without doing any fancy checking- USE ONLY FOR UNLOADING OFFSCREEN
func just_erase_tile(world_cell: Vector2i) -> void:
	world_tilemap.set_cell(world_cell)
	self.set_cell(world_cell)

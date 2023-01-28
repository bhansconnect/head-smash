extends TileMap


func _ready():
	var atlas := tile_set.get_source(0) as TileSetAtlasSource
	var tile_data = atlas.get_tile_data(Vector2i(1, 0), 0)
	
	# Set tile to invisible
	tile_data.modulate = Color(0,0,0,0)


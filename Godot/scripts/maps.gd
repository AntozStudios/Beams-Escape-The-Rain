extends RefCounted

enum { CLASSIC, HILLS, PASS, RIDGE }
enum { CLASSIC_CAMPAIGN, EARTH_CAMPAIGN }
const NAMES := ["Classic", "Erde"]
const DIFFICULTY := ["30 Level", "30 Level"]
const MAX_LEVELS := 30
const INITIAL_UNLOCKED_LEVELS := 10
const TERRAIN_COLORS := [Color("#f2ce99"), Color("#76c5c0"), Color("#a4cb9e")]
const TERRAIN_SIDE_COLORS := [Color("#c78f77"), Color("#608eaa"), Color("#ad8799")]

static func layout_for_level(campaign: int, level: int) -> int:
	if campaign == CLASSIC_CAMPAIGN:
		return CLASSIC
	return [HILLS,PASS,RIDGE][posmod(level-1,3)]

static func surface_for_level(campaign: int, level: int) -> int:
	if campaign == CLASSIC_CAMPAIGN:
		return 2
	return [2,0,1][posmod(level-1,3)]

static func terrain_for_cell(campaign: int, level: int, cell: Vector2i, layout: int, mirrored: bool, rows: int) -> int:
	if campaign == CLASSIC_CAMPAIGN:
		return 2
	# A narrow river winds through low ground, with sand banks and grassland around it.
	var preferred_x := roundi(2.0 * sin(float(cell.y) * 0.62 + float(level) * 0.83))
	var river_x := preferred_x
	var best_score := INF
	for x in range(-2,3):
		var height := elevation(layout,Vector2i(x,cell.y),mirrored,level%3,rows)
		var score := absf(float(x-preferred_x)) + maxf(0.0,float(height-1))*2.0
		if score < best_score:
			best_score = score
			river_x = x
	var distance_to_river := absi(cell.x-river_x)
	if distance_to_river == 0:
		return 1
	if distance_to_river == 1:
		return 0
	return 2

static func section_length(level: int) -> int:
	return 12 + posmod(level-1,3) * 3
# Rows run from the entrance towards the checkpoint. Digits are elevations.
# A dot is the valley floor, three steps below zero. A peak is six steps high.
const LAYOUTS := [
	[[]],
	[
		["..000..", "..0000.", "...1111", "....111", "....222", "...2222", "..2222^", "..222^^"],
		["..000..", "..000..", ".111...", ".1111..", "...222.", "...222.", "..2222.", "..222.."],
		["..000..", ".0000..", ".111...", "..1111.", "....222", "...222.", ".2222..", "..222.."]
	],
	[
		["..000..", ".00..^^", ".11..^^", ".11....", ".12222.", "....22.", "..3333.", "..333^^"],
		["..000..", "^^..00.", "^^..11.", "....11.", ".22221.", ".22....", ".3333..", "^^333.."],
		["..000..", ".00....", ".11..^^", ".11..^^", "..222..", ".2222..", "..3333.", "..333^^"]
	],
	[
		["..222..", ".222..^", ".11...^", ".000..^", "...0...", "...011.", "....22.", "...2222"],
		["..222..", "^..222.", "^...11.", "^..000.", "...0...", ".110...", ".22....", "2222..."],
		["..222..", "..222^.", "...11^.", "...000.", "...0...", "..011..", "..222..", "..222.."]
	]
]

static func elevation(map_id: int, cell: Vector2i, mirrored: bool, variation: int = 0, section_rows: int = 8) -> int:
	if map_id == CLASSIC:
		return 0
	var column := 3 - cell.x if mirrored else 3 + cell.x
	var pattern: Array = LAYOUTS[map_id][variation % LAYOUTS[map_id].size()]
	var source_row := roundi(float(cell.y) * 7.0 / float(section_rows - 1))
	var symbol: String = pattern[source_row][column]
	if symbol == ".":
		return -3
	if symbol == "^":
		return 6
	return symbol.to_int()

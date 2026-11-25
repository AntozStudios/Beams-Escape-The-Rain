extends RefCounted

enum { CLASSIC, HILLS, PASS, RIDGE }
const NAMES := ["Classic", "Grüne Hügel", "Eispass", "Sandgrat"]
const DIFFICULTY := ["Original", "Leicht", "Mittel", "Schwer"]
const SURFACES := [2, 2, 1, 0]
# Rows run from the entrance towards the checkpoint. Digits are elevations.
# A dot is the valley floor, three steps below zero. A peak is six steps high.
const ROWS := [
	[],
	["..000..", "..0000.", "...1111", "....111", "....222",
	 "...2222", "..2222^", "..222^^"],
	["..000..", ".00..^^", ".11..^^", ".11....", ".12222.",
	 "....22.", "..3333.", "..333^^"],
	["..222..", ".222..^", ".11...^", ".000..^", "...0...",
	 "...011.", "....22.", "...222^"]
]

static func elevation(map_id: int, cell: Vector2i, mirrored: bool) -> int:
	if map_id == CLASSIC:
		return 0
	var column := 3 - cell.x if mirrored else 3 + cell.x
	var symbol: String = ROWS[map_id][cell.y][column]
	if symbol == ".":
		return -3
	if symbol == "^":
		return 6
	return symbol.to_int()

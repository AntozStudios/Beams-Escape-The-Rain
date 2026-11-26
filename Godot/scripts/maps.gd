extends RefCounted

enum { CLASSIC, EARTH }
const RAIN_RED := Color("#c64052")
const NAMES := ["Classic", "Erde"]
const MAX_LEVELS := 30
const INITIAL_UNLOCKED_LEVELS := 10
const COLORS := [Color("#e9bd83"), Color("#76c5c0"), Color("#94be98")]

# Each row is one terrace. Adjacent centres differ by at most one tile,
# leaving a shared crossing between their three-tile-wide platforms.
var lift_row := -1
var centers := PackedInt32Array()
var heights := PackedInt32Array()
var surfaces := PackedInt32Array()

func generate(world: int, number: int) -> void:
	var rows := 13 + posmod(number-1,6) + (number-1)/6
	lift_row = rows/2
	var center := 0
	for row in rows:
		var bend := 2.0*sin(float(row)/(2.3+number%4*0.3)+number*0.67)
		if row > 1:
			center += clampi(roundi(bend)-center,-1,1)
		centers.append(center)
		var terrace := absi(posmod(row/2 + number,6)-3) if world == EARTH else 0
		heights.append(terrace + (3 if row > lift_row else 0))
		surfaces.append(1 if world == EARTH and terrace == 0 else (0 if world == EARTH and terrace == 1 else 2))

func contains(cell: Vector2i) -> bool:
	if cell.y == lift_row:
		return cell.x == centers[lift_row]
	return cell.y >= 0 and cell.y < centers.size() and absi(cell.x-centers[cell.y]) <= 1

func center_at(row: int) -> Vector2i:
	return Vector2i(centers[row],row)

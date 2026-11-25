extends RefCounted

# Unity Random.InitState and Range use four unsigned 32-bit Xorshift words.
const MASK := 0xffffffff
var words := PackedInt64Array([0,0,0,0])

func reset(seed_value: int) -> void:
	words[0] = seed_value & MASK
	for i in range(1,4):
		words[i] = (1812433253 * words[i-1] + 1) & MASK

func next_word() -> int:
	var shifted := (words[0] ^ (words[0] << 11)) & MASK
	var last := words[3]
	words[0] = words[1]
	words[1] = words[2]
	words[2] = last
	words[3] = (last ^ (last >> 19) ^ shifted ^ (shifted >> 8)) & MASK
	return words[3]

func rain_speed() -> float:
	var fraction := float(next_word() & 0x7fffff) / 8388607.0
	return lerpf(2000,500,fraction)

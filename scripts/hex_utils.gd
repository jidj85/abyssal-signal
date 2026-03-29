class_name HexUtils

## Hex math utilities using axial coordinates (q, r).
## Flat-top hexagons. Reference: Red Blob Games hex guide.

const SQRT3 := 1.7320508075688772  # sqrt(3)

# Default hex size in pixels (center to vertex)
const HEX_SIZE := 40.0


static func hex_to_pixel(hex: Vector2i, size: float = HEX_SIZE) -> Vector2:
	var x := size * 1.5 * hex.x
	var y := size * (SQRT3 * 0.5 * hex.x + SQRT3 * hex.y)
	return Vector2(x, y)


static func pixel_to_hex(pixel: Vector2, size: float = HEX_SIZE) -> Vector2i:
	# Convert pixel to fractional axial, then round
	var q := pixel.x * 2.0 / 3.0 / size
	var r := (-pixel.x / 3.0 + SQRT3 / 3.0 * pixel.y) / size
	return axial_round(q, r)


static func axial_round(fq: float, fr: float) -> Vector2i:
	var fs := -fq - fr
	var q := roundi(fq)
	var r := roundi(fr)
	var s := roundi(fs)

	var q_diff := absf(q - fq)
	var r_diff := absf(r - fr)
	var s_diff := absf(s - fs)

	if q_diff > r_diff and q_diff > s_diff:
		q = -r - s
	elif r_diff > s_diff:
		r = -q - s
	# else: s = -q - r (not needed, we only store q,r)

	return Vector2i(q, r)


static func hex_distance(a: Vector2i, b: Vector2i) -> int:
	var diff := a - b
	return (absi(diff.x) + absi(diff.x + diff.y) + absi(diff.y)) / 2


static func hex_neighbors(hex: Vector2i) -> Array[Vector2i]:
	return [
		hex + Vector2i(1, 0),
		hex + Vector2i(1, -1),
		hex + Vector2i(0, -1),
		hex + Vector2i(-1, 0),
		hex + Vector2i(-1, 1),
		hex + Vector2i(0, 1),
	]


static func is_in_grid(hex: Vector2i, radius: int) -> bool:
	return hex_distance(Vector2i.ZERO, hex) <= radius


static func get_all_hexes(radius: int) -> Array[Vector2i]:
	var hexes: Array[Vector2i] = []
	for q in range(-radius, radius + 1):
		var r1 := maxi(-radius, -q - radius)
		var r2 := mini(radius, -q + radius)
		for r in range(r1, r2 + 1):
			hexes.append(Vector2i(q, r))
	return hexes


static func hex_corner_offset(corner: int, size: float = HEX_SIZE) -> Vector2:
	# Flat-top hex: first corner at 0 degrees
	var angle_deg := 60.0 * corner
	var angle_rad := deg_to_rad(angle_deg)
	return Vector2(size * cos(angle_rad), size * sin(angle_rad))


static func hex_polygon(size: float = HEX_SIZE) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in 6:
		points.append(hex_corner_offset(i, size))
	return points


## Simple greedy step toward target — returns the neighbor of 'from' closest to 'to'.
## Returns 'from' if already at target or no valid step exists.
static func step_toward(from: Vector2i, to: Vector2i, valid_hexes: Dictionary) -> Vector2i:
	if from == to:
		return from

	var best := from
	var best_dist := hex_distance(from, to)

	for neighbor in hex_neighbors(from):
		if valid_hexes.has(neighbor):
			var d := hex_distance(neighbor, to)
			if d < best_dist:
				best_dist = d
				best = neighbor

	return best

extends Node2D
class_name Game

@export var grid_size := Vector2i(20, 20)
@export var cell_size := Vector2i(64, 64)
@export var grid_origin := Vector2.ZERO
@export var visible_tiles := 9
@export var recharge_tiles_count := 5
@export var trap_tiles_count := 5

@onready var player := $Player
@onready var cam := $Player/Camera2D

var recharge_tiles: Array[Vector2i] = []   # green tiles
var trap_tiles: Array[Vector2i] = []       # red tiles
var exit_tile: Vector2i = Vector2i(-1, -1) # yellow tile

func _ready() -> void:
	player.grid_pos = grid_size / 2
	player.global_position = cell_to_world(player.grid_pos)

	_configure_camera_limits()
	_spawn_special_tiles()
	get_viewport().size_changed.connect(_update_camera_zoom)

func _spawn_special_tiles() -> void:
	recharge_tiles.clear()
	trap_tiles.clear()
	exit_tile = Vector2i(-1, -1)

	var rng := RandomNumberGenerator.new()
	rng.randomize()

	# Green recharge tiles
	while recharge_tiles.size() < recharge_tiles_count:
		var pos := Vector2i(rng.randi_range(0, grid_size.x - 1), rng.randi_range(0, grid_size.y - 1))
		if pos != player.grid_pos and not recharge_tiles.has(pos):
			recharge_tiles.append(pos)

	# Red trap tiles
	while trap_tiles.size() < trap_tiles_count:
		var pos := Vector2i(rng.randi_range(0, grid_size.x - 1), rng.randi_range(0, grid_size.y - 1))
		if pos != player.grid_pos and not recharge_tiles.has(pos) and not trap_tiles.has(pos):
			trap_tiles.append(pos)

	# Yellow exit tile (distance >= 10 from player)
	while exit_tile == Vector2i(-1, -1):
		var pos := Vector2i(rng.randi_range(0, grid_size.x - 1), rng.randi_range(0, grid_size.y - 1))
		var dist = abs(pos.x - player.grid_pos.x) + abs(pos.y - player.grid_pos.y)
		if dist >= 10 and pos != player.grid_pos and not recharge_tiles.has(pos) and not trap_tiles.has(pos):
			exit_tile = pos

func cell_to_world(c: Vector2i) -> Vector2:
	var px_x := grid_origin.x + float(c.x) * float(cell_size.x) + float(cell_size.x) * 0.5
	var px_y := grid_origin.y + float(c.y) * float(cell_size.y) + float(cell_size.y) * 0.5
	return Vector2(px_x, px_y)

func world_to_cell(p: Vector2) -> Vector2i:
	var lx := (p.x - grid_origin.x) / float(cell_size.x)
	var ly := (p.y - grid_origin.y) / float(cell_size.y)
	return Vector2i(int(floor(lx)), int(floor(ly)))

func in_bounds(c: Vector2i) -> bool:
	return c.x >= 0 and c.y >= 0 and c.x < grid_size.x and c.y < grid_size.y

func _configure_camera_limits() -> void:
	var world_w := grid_size.x * cell_size.x
	var world_h := grid_size.y * cell_size.y
	cam.limit_left = grid_origin.x
	cam.limit_top = grid_origin.y
	cam.limit_right = grid_origin.x + world_w
	cam.limit_bottom = grid_origin.y + world_h

func _update_camera_zoom() -> void:
	var vp := get_viewport().get_visible_rect().size
	var desired_px_x := float(visible_tiles * cell_size.x)
	var desired_px_y := float(visible_tiles * cell_size.y)
	var zoom_x = desired_px_x / max(1.0, float(vp.x))
	var zoom_y = desired_px_y / max(1.0, float(vp.y))
	var z = max(zoom_x, zoom_y)
	cam.zoom = Vector2(z, z)

func _draw() -> void:
	var col_normal := Color(0.18, 0.18, 0.18, 1.0)
	var col_recharge := Color(0.0, 0.8, 0.0, 1.0)
	var col_trap := Color(0.8, 0.0, 0.0, 1.0)
	var col_exit := Color(0.95, 0.9, 0.1, 1.0)
	var dark := Color(0, 0, 0, 0.8)

	var w := grid_size.x * cell_size.x
	var h := grid_size.y * cell_size.y
	var top_left := grid_origin

	# draw tiles
	for cell in recharge_tiles:
		var rect := Rect2(grid_origin + Vector2(cell.x * cell_size.x, cell.y * cell_size.y), Vector2(cell_size))
		draw_rect(rect, col_recharge)

	for cell in trap_tiles:
		var rect := Rect2(grid_origin + Vector2(cell.x * cell_size.x, cell.y * cell_size.y), Vector2(cell_size))
		draw_rect(rect, col_trap)

	if exit_tile != Vector2i(-1, -1):
		var rect := Rect2(grid_origin + Vector2(exit_tile.x * cell_size.x, exit_tile.y * cell_size.y), Vector2(cell_size))
		draw_rect(rect, col_exit)

	# grid lines
	for x in range(grid_size.x + 1):
		var p := top_left + Vector2(float(x * cell_size.x), 0.0)
		draw_line(p, p + Vector2(0.0, float(h)), col_normal, 1.0)
	for y in range(grid_size.y + 1):
		var p := top_left + Vector2(0.0, float(y * cell_size.y))
		draw_line(p, p + Vector2(float(w), 0.0), col_normal, 1.0)

	# visibility mask
	var visible := get_visible_tiles()
	for x in range(grid_size.x):
		for y in range(grid_size.y):
			var cell := Vector2i(x,y)
			if not visible.has(cell):
				var rect := Rect2(grid_origin + Vector2(cell.x * cell_size.x, cell.y * cell_size.y), Vector2(cell_size))
				draw_rect(rect, dark)

func _process(_dt: float) -> void:
	queue_redraw()

# --- Tile consumption API ---

func consume_recharge_tile(cell: Vector2i) -> bool:
	if recharge_tiles.has(cell):
		recharge_tiles.erase(cell)
		return true
	return false

func consume_trap_tile(cell: Vector2i) -> int:
	if trap_tiles.has(cell):
		trap_tiles.erase(cell)
		var rng := RandomNumberGenerator.new()
		rng.randomize()
		return rng.randi_range(1, 3)
	return 0

func is_exit_tile(cell: Vector2i) -> bool:
	return exit_tile == cell
	
func get_visible_tiles() -> Array[Vector2i]:
	var tiles: Array[Vector2i] = []
	var p = player.grid_pos
	var dir = player.facing

	# forward
	var forward = p + dir
	if in_bounds(forward): tiles.append(forward)

	# left (perpendicular)
	var left := Vector2i(-dir.y, dir.x)
	var forward_left = p + left
	if in_bounds(forward_left): tiles.append(forward_left)

	# right (perpendicular)
	var right := Vector2i(dir.y, -dir.x)
	var forward_right = p + right
	if in_bounds(forward_right): tiles.append(forward_right)

	# current tile (always visible)
	tiles.append(p)

	return tiles

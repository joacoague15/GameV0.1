extends Node2D
class_name Game

@export var grid_size := Vector2i(20, 20)
@export var cell_size := Vector2i(64, 64)
@export var grid_origin := Vector2.ZERO
@export var visible_tiles := 9   # informational now

@onready var player := $Player
@onready var cam := $Player/Camera2D

func _ready() -> void:
	player.grid_pos = grid_size / 2
	player.global_position = cell_to_world(player.grid_pos)

	_configure_camera_limits()
	# Camera zoom stays at (1,1). The project stretch handles the 9×9 view.

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

func _draw() -> void:
	var col := Color(0.18, 0.18, 0.18, 1.0)
	var thick := 1.0
	var w := grid_size.x * cell_size.x
	var h := grid_size.y * cell_size.y
	var top_left := grid_origin

	for x in range(grid_size.x + 1):
		var p := top_left + Vector2(float(x * cell_size.x), 0.0)
		draw_line(p, p + Vector2(0.0, float(h)), col, thick)
	for y in range(grid_size.y + 1):
		var p := top_left + Vector2(0.0, float(y * cell_size.y))
		draw_line(p, p + Vector2(float(w), 0.0), col, thick)

func _process(_dt: float) -> void:
	queue_redraw()

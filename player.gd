extends Node2D
class_name GridPlayer

@export var move_time := 0.08

var grid_pos: Vector2i
var _is_moving := false

@onready var game: Game = get_parent() as Game

func _unhandled_input(event: InputEvent) -> void:
	if _is_moving:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var mouse_world := get_global_mouse_position()
		var clicked_cell := game.world_to_cell(mouse_world)
		if not game.in_bounds(clicked_cell):
			return
		var d := clicked_cell - grid_pos
		if abs(d.x) + abs(d.y) == 1:
			_move_to_cell(clicked_cell)

func _move_to_cell(next: Vector2i) -> void:
	if not game.in_bounds(next):
		return
	grid_pos = next
	var target: Vector2 = game.cell_to_world(grid_pos)
	_tween_to(target)

func _tween_to(target: Vector2) -> void:
	_is_moving = true
	var tw := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "global_position", target, move_time)
	tw.finished.connect(func(): _is_moving = false)

extends Node2D
class_name GridPlayer

@export var move_time := 0.08
@export var max_light := 101

var grid_pos: Vector2i
var _is_moving = false
var light: int

@onready var game: Game = get_parent() as Game

func _ready() -> void:
	light = max_light

func _unhandled_input(event: InputEvent) -> void:
	if _is_moving or light <= 0:
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
	
	# ⚡ Trigger tile effects immediately upon entering
	_check_special_tiles()

	var target: Vector2 = game.cell_to_world(grid_pos)
	_tween_to(target)

func _tween_to(target: Vector2) -> void:
	_is_moving = true
	var tw := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "global_position", target, move_time)
	tw.finished.connect(func():
		_is_moving = false
		_consume_light()   # movement cost happens after reaching tile
	)

func _check_special_tiles() -> void:
	# Recharge (green)
	if game.consume_recharge_tile(grid_pos):
		light = max_light
		print("💡 Recharged to full!")

	# Trap (red)
	var loss := game.consume_trap_tile(grid_pos)
	if loss > 0:
		light = max(light - loss, 0)
		print("☠️ Trap! Lost ", loss, " light. Remaining: ", light)

	# Exit (yellow)
	if game.is_exit_tile(grid_pos):
		print("🚪 Exit reached! 🎉")

func _consume_light() -> void:
	light = max(light - 1, 0)
	var hud_label: Label = get_tree().root.get_node("Game/CanvasLayer/HUD/LightLabel")
	if hud_label:
		hud_label.text = "Light: %d" % light

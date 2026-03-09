class_name CoordGridOverlay
extends Control

# Draws a 10x10 coordinate grid overlay on the viewport.
# Shows col/row labels to help students understand the coordinate system.
# Shown when a place_building block's parameter widget is focused.

const GRID_SIZE := 10
const CELL_SIZE := 20
const GRID_TOTAL := GRID_SIZE * CELL_SIZE
const MARGIN_LEFT := 30
const MARGIN_TOP := 20
const LABEL_FONT_SIZE := 10
const GRID_LINE_COLOR := Color("#CCCCCC")
const HIGHLIGHT_COLOR := Color("#43A7BE", 0.3)
const LABEL_COLOR := Color("#4A5568")
const BG_COLOR := Color("#FFFFFF", 0.9)

var highlight_col := 0
var highlight_row := 0


func _ready() -> void:
	# Position in bottom-right of viewport
	set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	custom_minimum_size = Vector2(GRID_TOTAL + MARGIN_LEFT + 20, GRID_TOTAL + MARGIN_TOP + 20)
	size = custom_minimum_size
	offset_left = -size.x - 10
	offset_top = -size.y - 10
	offset_right = -10
	offset_bottom = -10
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## Shows the overlay with a highlighted cell
func show_overlay(col: int, row: int) -> void:
	highlight_col = clampi(col, 0, GRID_SIZE - 1)
	highlight_row = clampi(row, 0, GRID_SIZE - 1)
	visible = true
	queue_redraw()


## Hides the overlay
func hide_overlay() -> void:
	visible = false


func _draw() -> void:
	# Background
	draw_rect(Rect2(Vector2.ZERO, size), BG_COLOR)

	var origin := Vector2(MARGIN_LEFT, MARGIN_TOP)

	# Draw highlighted cell
	var hl_pos := origin + Vector2(highlight_col * CELL_SIZE, highlight_row * CELL_SIZE)
	draw_rect(Rect2(hl_pos, Vector2(CELL_SIZE, CELL_SIZE)), HIGHLIGHT_COLOR)

	# Draw grid lines
	for i in range(GRID_SIZE + 1):
		var x := origin.x + i * CELL_SIZE
		var y := origin.y + i * CELL_SIZE
		draw_line(Vector2(x, origin.y), Vector2(x, origin.y + GRID_TOTAL), GRID_LINE_COLOR, 1.0)
		draw_line(Vector2(origin.x, y), Vector2(origin.x + GRID_TOTAL, y), GRID_LINE_COLOR, 1.0)

	# Draw column labels across top
	for c in range(GRID_SIZE):
		var label_pos := Vector2(origin.x + c * CELL_SIZE + CELL_SIZE * 0.3, origin.y - 4)
		draw_string(ThemeDB.fallback_font, label_pos, str(c), HORIZONTAL_ALIGNMENT_LEFT, -1, LABEL_FONT_SIZE, LABEL_COLOR)

	# Draw row labels down left side
	for r in range(GRID_SIZE):
		var label_pos := Vector2(2, origin.y + r * CELL_SIZE + CELL_SIZE * 0.7)
		draw_string(ThemeDB.fallback_font, label_pos, str(r), HORIZONTAL_ALIGNMENT_LEFT, -1, LABEL_FONT_SIZE, LABEL_COLOR)

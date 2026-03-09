class_name HudMission
extends PanelContainer

# Tutorial Panel — displays step progress, mayor dialogue, instructions,
# hints, and a Next button for the step-based mission system.
# Connects to MissionManager signals to update on step changes.

const COLOR_BG := Color("#FAF7F2")
const COLOR_PANEL_BG := Color("#F4EFE7")
const COLOR_TEXT := Color("#4A5568")
const COLOR_ACCENT := Color("#43A7BE")
const COLOR_WHITE := Color("#FFFFFF")
const COLOR_SUCCESS := Color("#2A9D8F")
const COLOR_BORDER := Color("#EDE6DB")
const CORNER_RADIUS := 8
const TOTAL_STEPS := 10

var current_step: Dictionary = {}

# UI node references
var progress_label: Label = null
var progress_bar: ProgressBar = null
var mayor_label: RichTextLabel = null
var instruction_header: Label = null
var instruction_label: RichTextLabel = null
var hint_button: Button = null
var hint_label: RichTextLabel = null
var next_button: Button = null
var grid_diagram: Control = null


func _ready() -> void:
	_build_layout()


## Builds the tutorial panel layout
func _build_layout() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	custom_minimum_size = Vector2(0, 200)

	# Panel background
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = COLOR_WHITE
	panel_style.set_corner_radius_all(CORNER_RADIUS)
	panel_style.set_content_margin_all(0)
	panel_style.shadow_color = Color(0, 0, 0, 0.10)
	panel_style.shadow_size = 3
	panel_style.shadow_offset = Vector2(0, 2)
	add_theme_stylebox_override("panel", panel_style)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 10)
	add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)

	# Progress label
	progress_label = Label.new()
	progress_label.text = "Step 1 of 10"
	progress_label.add_theme_color_override("font_color", COLOR_ACCENT)
	vbox.add_child(progress_label)

	# Progress bar
	progress_bar = ProgressBar.new()
	progress_bar.min_value = 0
	progress_bar.max_value = TOTAL_STEPS
	progress_bar.value = 1
	progress_bar.custom_minimum_size = Vector2(0, 8)
	progress_bar.show_percentage = false
	var pb_bg := StyleBoxFlat.new()
	pb_bg.bg_color = COLOR_BORDER
	pb_bg.set_corner_radius_all(4)
	progress_bar.add_theme_stylebox_override("background", pb_bg)
	var pb_fill := StyleBoxFlat.new()
	pb_fill.bg_color = COLOR_ACCENT
	pb_fill.set_corner_radius_all(4)
	progress_bar.add_theme_stylebox_override("fill", pb_fill)
	vbox.add_child(progress_bar)

	# Mayor dialogue
	mayor_label = RichTextLabel.new()
	mayor_label.bbcode_enabled = true
	mayor_label.fit_content = true
	mayor_label.scroll_active = false
	mayor_label.add_theme_color_override("default_color", COLOR_TEXT)
	vbox.add_child(mayor_label)

	# Separator
	var sep := HSeparator.new()
	sep.add_theme_color_override("separator", COLOR_BORDER)
	vbox.add_child(sep)

	# Instruction header
	instruction_header = Label.new()
	instruction_header.text = "INSTRUCTIONS"
	instruction_header.add_theme_color_override("font_color", COLOR_ACCENT)
	vbox.add_child(instruction_header)

	# Instruction text
	instruction_label = RichTextLabel.new()
	instruction_label.bbcode_enabled = true
	instruction_label.fit_content = true
	instruction_label.scroll_active = false
	instruction_label.add_theme_color_override("default_color", COLOR_TEXT)
	vbox.add_child(instruction_label)

	# Grid diagram (shown for explain steps with show_grid_diagram)
	grid_diagram = GridDiagram.new()
	grid_diagram.visible = false
	grid_diagram.custom_minimum_size = Vector2(200, 200)
	vbox.add_child(grid_diagram)

	# Hint button
	hint_button = Button.new()
	hint_button.text = "Show Hint"
	hint_button.visible = false
	hint_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_style_hint_button()
	hint_button.pressed.connect(_on_hint_pressed)
	vbox.add_child(hint_button)

	# Hint label (hidden until requested)
	hint_label = RichTextLabel.new()
	hint_label.bbcode_enabled = true
	hint_label.fit_content = true
	hint_label.scroll_active = false
	hint_label.visible = false
	hint_label.add_theme_color_override("default_color", COLOR_SUCCESS)
	vbox.add_child(hint_label)

	# Next button (only for explain steps)
	next_button = Button.new()
	next_button.text = "Next  ->"
	next_button.visible = false
	next_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_style_next_button()
	next_button.pressed.connect(_on_next_pressed)
	vbox.add_child(next_button)


## Loads a step Dictionary into the panel
func load_step(step: Dictionary) -> void:
	current_step = step
	if step.is_empty():
		return

	var step_id: int = step.get("id", 1)

	# Update progress
	progress_label.text = "Step %d of %d" % [step_id, TOTAL_STEPS]
	progress_bar.value = step_id

	# Mayor dialogue
	mayor_label.clear()
	mayor_label.append_text(step.get("mayor_dialogue", ""))

	# Instructions
	instruction_label.clear()
	instruction_label.append_text(step.get("instruction", ""))

	# Grid diagram
	var show_diagram: bool = step.get("show_grid_diagram", false)
	if grid_diagram:
		grid_diagram.visible = show_diagram

	# Reset hint
	hint_button.visible = false
	hint_label.visible = false
	hint_label.clear()

	# Show hint button only for non-explain steps
	if step.type != "explain" and step.get("hint", "") != "":
		# Hint button will be shown by the timer in mission_1.gd via show_hint()
		pass

	# Next button only on explain steps
	next_button.visible = (step.type == "explain")

	# Update block editor starter blocks if it exists
	var block_editor = get_tree().get_first_node_in_group("block_editor")
	if block_editor and block_editor.has_method("set_starter_blocks"):
		var starter: String = step.get("starter_code", "")
		block_editor.set_starter_blocks(starter)


## Shows the hint text
func show_hint() -> void:
	if current_step.is_empty():
		return

	var hint_text: String = current_step.get("hint", "")
	if hint_text == "":
		return

	hint_button.visible = true
	hint_button.text = "Hint (shown)"
	hint_label.clear()
	hint_label.append_text(hint_text)
	hint_label.visible = true


## Called when step advances
func on_step_advanced(step_id: int) -> void:
	# Get mission from MissionManager
	if MissionManager.active_mission and MissionManager.active_mission.has_method("get_step"):
		var step: Dictionary = MissionManager.active_mission.get_step(step_id)
		load_step(step)


func _on_hint_pressed() -> void:
	show_hint()


func _on_next_pressed() -> void:
	# Advance to next step (for explain-type steps)
	if MissionManager.active_mission and MissionManager.active_mission.has_method("advance_step"):
		MissionManager.active_mission.advance_step()


func _style_hint_button() -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = COLOR_PANEL_BG
	normal.set_corner_radius_all(6)
	normal.set_content_margin_all(8)
	hint_button.add_theme_stylebox_override("normal", normal)
	hint_button.add_theme_color_override("font_color", COLOR_TEXT)


func _style_next_button() -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = COLOR_ACCENT
	normal.set_corner_radius_all(6)
	normal.set_content_margin_all(10)
	next_button.add_theme_stylebox_override("normal", normal)

	var hover := StyleBoxFlat.new()
	hover.bg_color = COLOR_ACCENT.lightened(0.1)
	hover.set_corner_radius_all(6)
	hover.set_content_margin_all(10)
	next_button.add_theme_stylebox_override("hover", hover)

	next_button.add_theme_color_override("font_color", COLOR_WHITE)
	next_button.add_theme_color_override("font_hover_color", COLOR_WHITE)


## Inner class for the grid diagram drawn in step 1
class GridDiagram extends Control:
	const DIAGRAM_GRID_SIZE := 5
	const DIAGRAM_CELL_SIZE := 36
	const DIAGRAM_MARGIN := 24
	const LINE_COLOR := Color("#CCCCCC")
	const HIGHLIGHT_COLOR := Color("#43A7BE", 0.3)
	const LABEL_COLOR := Color("#4A5568")
	const ACCENT := Color("#43A7BE")

	func _draw() -> void:
		var origin := Vector2(DIAGRAM_MARGIN, DIAGRAM_MARGIN)
		var total := DIAGRAM_GRID_SIZE * DIAGRAM_CELL_SIZE

		# Background
		draw_rect(Rect2(Vector2.ZERO, size), Color("#FAF7F2"))

		# Highlight cell (0,0)
		draw_rect(Rect2(origin, Vector2(DIAGRAM_CELL_SIZE, DIAGRAM_CELL_SIZE)), HIGHLIGHT_COLOR)

		# Grid lines
		for i in range(DIAGRAM_GRID_SIZE + 1):
			var x := origin.x + i * DIAGRAM_CELL_SIZE
			var y := origin.y + i * DIAGRAM_CELL_SIZE
			draw_line(Vector2(x, origin.y), Vector2(x, origin.y + total), LINE_COLOR, 1.0)
			draw_line(Vector2(origin.x, y), Vector2(origin.x + total, y), LINE_COLOR, 1.0)

		# Column labels across top
		for c in range(DIAGRAM_GRID_SIZE):
			var pos := Vector2(origin.x + c * DIAGRAM_CELL_SIZE + 6, origin.y - 6)
			draw_string(ThemeDB.fallback_font, pos, "col %d" % c, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, LABEL_COLOR)

		# Row labels down left side
		for r in range(DIAGRAM_GRID_SIZE):
			var pos := Vector2(0, origin.y + r * DIAGRAM_CELL_SIZE + DIAGRAM_CELL_SIZE * 0.6)
			draw_string(ThemeDB.fallback_font, pos, "r%d" % r, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, LABEL_COLOR)

		# Star at (0,0)
		var star_center := origin + Vector2(DIAGRAM_CELL_SIZE * 0.5, DIAGRAM_CELL_SIZE * 0.5)
		draw_string(ThemeDB.fallback_font, star_center - Vector2(4, -4), "*", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, ACCENT)

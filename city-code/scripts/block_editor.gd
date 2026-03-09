class_name BlockEditor
extends PanelContainer

# Block Coding Editor — visual block-based coding interface.
# Students click blocks from the palette to add them to the workspace sequence.
# Blocks can be reordered and removed. The editor generates GDScript code
# that is executed through the same CodeRunner pipeline as the text editor.

signal code_changed(code: String)
signal mode_switched(is_block_mode: bool)

# -- Palette colors (Machi Koro inspired) --
const COLOR_BG := Color("#FAF7F2")
const COLOR_PANEL_BG := Color("#F4EFE7")
const COLOR_TEXT := Color("#4A5568")
const COLOR_ACCENT := Color("#43A7BE")
const COLOR_WHITE := Color("#FFFFFF")
const COLOR_BORDER := Color("#EDE6DB")

# Category colors
const COLOR_PLACE_HEADER := Color("#E8A838")
const COLOR_PLACE_BLOCK := Color("#F5C842")
const COLOR_REPEAT_HEADER := Color("#C0392B")
const COLOR_REPEAT_BLOCK := Color("#E74C3C")
const COLOR_VARIABLES_HEADER := Color("#8E44AD")
const COLOR_VARIABLES_BLOCK := Color("#9B59B6")
const COLOR_PRINT_HEADER := Color("#27AE60")
const COLOR_PRINT_BLOCK := Color("#2ECC71")

const TOP_BAR_HEIGHT := 48
const PALETTE_WIDTH := 160
const PREFS_PATH := "user://prefs.cfg"

# Block definitions
var block_definitions: Array = [
	{
		"id": "place_building",
		"category": "PLACE",
		"label": "place building",
		"params": [
			{"name": "type", "widget": "dropdown", "options": ["house", "shop", "park", "tree", "road"]},
			{"name": "col", "widget": "spinbox", "min": 0, "max": 9, "default": 0},
			{"name": "row", "widget": "spinbox", "min": 0, "max": 9, "default": 0},
		],
		"color": "#F5C842",
		"code_template": 'place_building("{type}", {col}, {row})',
	},
	{
		"id": "repeat",
		"category": "REPEAT",
		"label": "repeat",
		"params": [
			{"name": "times", "widget": "spinbox", "min": 1, "max": 20, "default": 3},
		],
		"color": "#E74C3C",
		"is_container": true,
		"code_template": "repeat {times}:\n{children}",
	},
	{
		"id": "print",
		"category": "PRINT",
		"label": "print",
		"params": [
			{"name": "msg", "widget": "lineedit", "placeholder": "Hello!"},
		],
		"color": "#2ECC71",
		"code_template": 'print("{msg}")',
	},
]

var is_block_mode := true

# UI node references
var _top_bar: HBoxContainer = null
var _block_mode_btn: Button = null
var _epic_mode_btn: Button = null
var _run_btn: Button = null
var _palette_scroll: ScrollContainer = null
var _palette_vbox: VBoxContainer = null
var _workspace_scroll: ScrollContainer = null
var _workspace_container: VBoxContainer = null
var _coord_overlay: Control = null


func _ready() -> void:
	add_to_group("block_editor")
	_load_mode_preference()
	_build_layout()
	_populate_palette()
	_create_coord_overlay()


## Builds the complete editor layout programmatically
func _build_layout() -> void:
	# Main background style
	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = COLOR_BG
	bg_style.set_corner_radius_all(8)
	bg_style.set_content_margin_all(0)
	add_theme_stylebox_override("panel", bg_style)

	var main_vbox := VBoxContainer.new()
	main_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_theme_constant_override("separation", 0)
	add_child(main_vbox)

	# Top bar
	_top_bar = HBoxContainer.new()
	_top_bar.custom_minimum_size = Vector2(0, TOP_BAR_HEIGHT)
	_top_bar.add_theme_constant_override("separation", 4)
	var top_margin := MarginContainer.new()
	top_margin.add_theme_constant_override("margin_left", 8)
	top_margin.add_theme_constant_override("margin_right", 8)
	top_margin.add_theme_constant_override("margin_top", 6)
	top_margin.add_theme_constant_override("margin_bottom", 6)
	main_vbox.add_child(top_margin)
	top_margin.add_child(_top_bar)

	_block_mode_btn = Button.new()
	_block_mode_btn.text = "Block Mode"
	_block_mode_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_block_mode_btn.pressed.connect(_on_block_mode_pressed)
	_top_bar.add_child(_block_mode_btn)

	_epic_mode_btn = Button.new()
	_epic_mode_btn.text = "Epic Mode"
	_epic_mode_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_epic_mode_btn.pressed.connect(_on_epic_mode_pressed)
	_top_bar.add_child(_epic_mode_btn)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_top_bar.add_child(spacer)

	_run_btn = Button.new()
	_run_btn.text = "Run"
	_run_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_run_btn.pressed.connect(_on_run_pressed)
	_style_run_button()
	_top_bar.add_child(_run_btn)

	# Content area: palette + workspace side by side
	var content_hbox := HSplitContainer.new()
	content_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(content_hbox)

	# Palette (left side)
	_palette_scroll = ScrollContainer.new()
	_palette_scroll.custom_minimum_size = Vector2(PALETTE_WIDTH, 0)
	_palette_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_palette_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content_hbox.add_child(_palette_scroll)

	_palette_vbox = VBoxContainer.new()
	_palette_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_palette_vbox.add_theme_constant_override("separation", 4)
	_palette_scroll.add_child(_palette_vbox)

	# Workspace (right side)
	var workspace_panel := PanelContainer.new()
	workspace_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	workspace_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var ws_style := StyleBoxFlat.new()
	ws_style.bg_color = COLOR_WHITE
	ws_style.set_corner_radius_all(6)
	ws_style.set_content_margin_all(8)
	ws_style.border_color = COLOR_BORDER
	ws_style.set_border_width_all(1)
	workspace_panel.add_theme_stylebox_override("panel", ws_style)
	content_hbox.add_child(workspace_panel)

	_workspace_scroll = ScrollContainer.new()
	_workspace_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_workspace_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_workspace_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	workspace_panel.add_child(_workspace_scroll)

	_workspace_container = VBoxContainer.new()
	_workspace_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_workspace_container.add_theme_constant_override("separation", 6)
	_workspace_scroll.add_child(_workspace_container)

	# Apply mode button styles
	_update_mode_buttons()


## Populates the palette with block categories and blocks
func _populate_palette() -> void:
	if not _palette_vbox:
		return

	var categories := {
		"PLACE": {"header_color": COLOR_PLACE_HEADER, "blocks": []},
		"REPEAT": {"header_color": COLOR_REPEAT_HEADER, "blocks": []},
		"PRINT": {"header_color": COLOR_PRINT_HEADER, "blocks": []},
	}

	for def in block_definitions:
		var cat: String = def.get("category", "")
		if cat in categories:
			categories[cat].blocks.append(def)

	for cat_name in ["PLACE", "REPEAT", "PRINT"]:
		var cat_data: Dictionary = categories[cat_name]
		_add_palette_header(cat_name, cat_data.header_color)
		for block_def in cat_data.blocks:
			_add_palette_block(block_def)


## Adds a category header to the palette
func _add_palette_header(title: String, color: Color) -> void:
	var header := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(4)
	style.set_content_margin_all(6)
	header.add_theme_stylebox_override("panel", style)

	var label := Label.new()
	label.text = title
	label.add_theme_color_override("font_color", COLOR_WHITE)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_child(label)

	_palette_vbox.add_child(header)


## Adds a clickable block button to the palette
func _add_palette_block(definition: Dictionary) -> void:
	var btn := Button.new()
	btn.text = "  " + definition.get("label", "block")
	btn.custom_minimum_size = Vector2(0, 40)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	var block_color := Color(definition.get("color", "#CCCCCC"))
	var normal := StyleBoxFlat.new()
	normal.bg_color = block_color
	normal.set_corner_radius_all(6)
	normal.set_content_margin_all(8)
	btn.add_theme_stylebox_override("normal", normal)

	var hover := StyleBoxFlat.new()
	hover.bg_color = block_color.lightened(0.15)
	hover.set_corner_radius_all(6)
	hover.set_content_margin_all(8)
	btn.add_theme_stylebox_override("hover", hover)

	var pressed := StyleBoxFlat.new()
	pressed.bg_color = block_color.darkened(0.1)
	pressed.set_corner_radius_all(6)
	pressed.set_content_margin_all(8)
	btn.add_theme_stylebox_override("pressed", pressed)

	btn.add_theme_color_override("font_color", COLOR_WHITE)
	btn.add_theme_color_override("font_hover_color", COLOR_WHITE)
	btn.add_theme_color_override("font_pressed_color", COLOR_WHITE)

	btn.pressed.connect(_on_palette_block_clicked.bind(definition))
	_palette_vbox.add_child(btn)


## Creates and adds a WorkspaceBlock to the workspace sequence
func _on_palette_block_clicked(definition: Dictionary) -> void:
	var block := WorkspaceBlock.new()
	block.setup(definition)
	block.block_changed.connect(_on_workspace_changed)
	block.block_remove_requested.connect(_on_block_remove)
	_workspace_container.add_child(block)

	# Flash animation
	var tween := create_tween()
	tween.tween_property(block, "modulate", Color(1.3, 1.3, 1.3, 1.0), 0.08)
	tween.tween_property(block, "modulate", Color.WHITE, 0.15)

	_on_workspace_changed()


## Removes a block from the workspace
func _on_block_remove(block: WorkspaceBlock) -> void:
	block.queue_free()
	# Wait a frame for the node to be freed
	await get_tree().process_frame
	_on_workspace_changed()


## Called when any block in the workspace changes (added, removed, param changed)
func _on_workspace_changed() -> void:
	code_changed.emit(generate_code())


## Generates the complete GDScript code from all workspace blocks
func generate_code() -> String:
	var lines: PackedStringArray = []
	for child in _workspace_container.get_children():
		if child is WorkspaceBlock:
			lines.append(child.to_code())
	return "\n".join(lines)


## Clears all blocks from the workspace
func clear_workspace() -> void:
	for child in _workspace_container.get_children():
		child.queue_free()
	await get_tree().process_frame
	_on_workspace_changed()


## Sets the workspace to display blocks matching the given code (best effort)
func set_starter_blocks(starter_code: String) -> void:
	# Clear existing blocks
	for child in _workspace_container.get_children():
		child.queue_free()
	await get_tree().process_frame

	if starter_code.is_empty():
		_on_workspace_changed()
		return

	var lines := starter_code.split("\n")
	for line in lines:
		var stripped := line.strip_edges()
		if stripped.begins_with("place_building"):
			# Parse: place_building("house", 2, 3)
			var inner := stripped.trim_prefix("place_building(").trim_suffix(")")
			var parts := inner.split(",")
			if parts.size() == 3:
				var btype := parts[0].strip_edges().trim_prefix('"').trim_suffix('"')
				var col_val := parts[1].strip_edges().to_int()
				var row_val := parts[2].strip_edges().to_int()

				var block := WorkspaceBlock.new()
				block.setup(block_definitions[0])  # place_building definition
				block.block_changed.connect(_on_workspace_changed)
				block.block_remove_requested.connect(_on_block_remove)
				_workspace_container.add_child(block)

				# Pre-fill param values after node is in tree
				await get_tree().process_frame
				block.set_param_value("type", btype)
				block.set_param_value("col", col_val)
				block.set_param_value("row", row_val)

	_on_workspace_changed()


# -- Mode Toggle --

func _on_block_mode_pressed() -> void:
	if is_block_mode:
		return
	is_block_mode = true
	_update_mode_buttons()
	_save_mode_preference()
	mode_switched.emit(true)


func _on_epic_mode_pressed() -> void:
	if not is_block_mode:
		return
	is_block_mode = false
	_update_mode_buttons()
	_save_mode_preference()
	mode_switched.emit(false)


func _update_mode_buttons() -> void:
	if not _block_mode_btn or not _epic_mode_btn:
		return
	_style_mode_button(_block_mode_btn, is_block_mode)
	_style_mode_button(_epic_mode_btn, not is_block_mode)


func _style_mode_button(btn: Button, active: bool) -> void:
	var style := StyleBoxFlat.new()
	if active:
		style.bg_color = COLOR_ACCENT
		btn.add_theme_color_override("font_color", COLOR_WHITE)
		btn.add_theme_color_override("font_hover_color", COLOR_WHITE)
	else:
		style.bg_color = Color.TRANSPARENT
		style.border_color = COLOR_ACCENT
		style.set_border_width_all(2)
		btn.add_theme_color_override("font_color", COLOR_ACCENT)
		btn.add_theme_color_override("font_hover_color", COLOR_ACCENT)

	style.set_corner_radius_all(6)
	style.set_content_margin_all(8)
	btn.add_theme_stylebox_override("normal", style)

	var hover := style.duplicate()
	if active:
		hover.bg_color = COLOR_ACCENT.lightened(0.1)
	btn.add_theme_stylebox_override("hover", hover)


func _style_run_button() -> void:
	if not _run_btn:
		return

	var normal := StyleBoxFlat.new()
	normal.bg_color = COLOR_ACCENT
	normal.set_corner_radius_all(6)
	normal.set_content_margin_all(10)
	_run_btn.add_theme_stylebox_override("normal", normal)

	var hover := StyleBoxFlat.new()
	hover.bg_color = COLOR_ACCENT.lightened(0.1)
	hover.set_corner_radius_all(6)
	hover.set_content_margin_all(10)
	_run_btn.add_theme_stylebox_override("hover", hover)

	_run_btn.add_theme_color_override("font_color", COLOR_WHITE)
	_run_btn.add_theme_color_override("font_hover_color", COLOR_WHITE)


func _on_run_pressed() -> void:
	if CodeRunner:
		CodeRunner.run_code(generate_code())


# -- Preference Persistence --

func _save_mode_preference() -> void:
	var config := ConfigFile.new()
	config.load(PREFS_PATH)
	config.set_value("editor", "mode", "block" if is_block_mode else "epic")
	config.save(PREFS_PATH)


func _load_mode_preference() -> void:
	var config := ConfigFile.new()
	if config.load(PREFS_PATH) == OK:
		var mode: String = config.get_value("editor", "mode", "block")
		is_block_mode = (mode == "block")


# -- Coordinate Helper Overlay --

func _create_coord_overlay() -> void:
	_coord_overlay = CoordGridOverlay.new()
	_coord_overlay.add_to_group("coord_overlay")
	_coord_overlay.visible = false
	# Add as CanvasLayer child so it draws over the 3D viewport
	var canvas := CanvasLayer.new()
	canvas.layer = 10
	add_child(canvas)
	canvas.add_child(_coord_overlay)

class_name WorkspaceBlock
extends PanelContainer

# A single block instance in the block coding workspace.
# Displays the block label, inline parameter widgets, and controls
# for reordering/removing the block.

signal block_changed
signal block_remove_requested(block: WorkspaceBlock)
signal block_drag_started(block: WorkspaceBlock)

const CORNER_RADIUS := 8
const BLOCK_MIN_HEIGHT := 48
const HANDLE_WIDTH := 24
const REMOVE_BTN_WIDTH := 28

var block_id: String = ""
var block_color: Color = Color.WHITE
var block_label: String = ""
var code_template: String = ""
var is_container: bool = false
var params: Array = []

# Runtime widget references for reading param values
var _param_widgets: Dictionary = {}

# Child blocks for container blocks (repeat)
var child_blocks: Array = []


## Initializes the block from a block definition Dictionary
func setup(definition: Dictionary) -> void:
	block_id = definition.get("id", "")
	block_color = Color(definition.get("color", "#CCCCCC"))
	block_label = definition.get("label", "block")
	code_template = definition.get("code_template", "")
	is_container = definition.get("is_container", false)
	params = definition.get("params", [])

	_build_ui()


## Builds the visual layout of the block
func _build_ui() -> void:
	custom_minimum_size = Vector2(0, BLOCK_MIN_HEIGHT)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# Block background style
	var style := StyleBoxFlat.new()
	style.bg_color = block_color
	style.set_corner_radius_all(CORNER_RADIUS)
	style.set_content_margin_all(6)
	style.content_margin_left = 4
	style.content_margin_right = 4
	style.shadow_color = Color(0, 0, 0, 0.12)
	style.shadow_size = 2
	style.shadow_offset = Vector2(0, 1)
	add_theme_stylebox_override("panel", style)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 6)
	add_child(hbox)

	# Grab handle
	var handle := Label.new()
	handle.text = "="
	handle.custom_minimum_size = Vector2(HANDLE_WIDTH, 0)
	handle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	handle.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	handle.add_theme_color_override("font_color", Color(1, 1, 1, 0.6))
	handle.mouse_filter = Control.MOUSE_FILTER_PASS
	handle.tooltip_text = "Drag to reorder"
	hbox.add_child(handle)

	# Block label
	var label := Label.new()
	label.text = block_label
	label.add_theme_color_override("font_color", Color.WHITE)
	hbox.add_child(label)

	# Parameter widgets
	for p in params:
		var widget := _create_param_widget(p)
		if widget:
			hbox.add_child(widget)

	# Spacer
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(spacer)

	# Remove button
	var remove_btn := Button.new()
	remove_btn.text = "x"
	remove_btn.custom_minimum_size = Vector2(REMOVE_BTN_WIDTH, REMOVE_BTN_WIDTH)
	remove_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var rm_style := StyleBoxFlat.new()
	rm_style.bg_color = Color(1, 1, 1, 0.2)
	rm_style.set_corner_radius_all(4)
	rm_style.set_content_margin_all(2)
	remove_btn.add_theme_stylebox_override("normal", rm_style)
	var rm_hover := StyleBoxFlat.new()
	rm_hover.bg_color = Color(1, 0.3, 0.3, 0.5)
	rm_hover.set_corner_radius_all(4)
	rm_hover.set_content_margin_all(2)
	remove_btn.add_theme_stylebox_override("hover", rm_hover)
	remove_btn.add_theme_color_override("font_color", Color.WHITE)
	remove_btn.add_theme_color_override("font_hover_color", Color.WHITE)
	remove_btn.pressed.connect(_on_remove_pressed)
	hbox.add_child(remove_btn)


## Creates an inline widget for a parameter definition
func _create_param_widget(param: Dictionary) -> Control:
	var widget_type: String = param.get("widget", "")
	var param_name: String = param.get("name", "")

	match widget_type:
		"dropdown":
			var option := OptionButton.new()
			var options: Array = param.get("options", [])
			for opt in options:
				option.add_item(str(opt))
			option.item_selected.connect(_on_param_changed)
			_param_widgets[param_name] = option
			return option

		"spinbox":
			var spin := SpinBox.new()
			spin.min_value = param.get("min", 0)
			spin.max_value = param.get("max", 9)
			spin.value = param.get("default", 0)
			spin.custom_minimum_size = Vector2(70, 0)
			spin.value_changed.connect(_on_spin_changed)
			# Connect focus signals for coordinate overlay
			var line_edit := spin.get_line_edit()
			if line_edit:
				line_edit.focus_entered.connect(_on_param_focus_entered.bind(param_name))
				line_edit.focus_exited.connect(_on_param_focus_exited.bind(param_name))
			_param_widgets[param_name] = spin
			return spin

		"lineedit":
			var edit := LineEdit.new()
			edit.placeholder_text = param.get("placeholder", "")
			edit.custom_minimum_size = Vector2(100, 0)
			edit.text_changed.connect(_on_text_param_changed)
			edit.focus_entered.connect(_on_param_focus_entered.bind(param_name))
			edit.focus_exited.connect(_on_param_focus_exited.bind(param_name))
			_param_widgets[param_name] = edit
			return edit

	return null


## Generates GDScript code from this block's template and current param values
func to_code() -> String:
	var code := code_template

	for param_name in _param_widgets:
		var widget = _param_widgets[param_name]
		var value_str := ""

		if widget is OptionButton:
			value_str = widget.get_item_text(widget.selected)
		elif widget is SpinBox:
			value_str = str(int(widget.value))
		elif widget is LineEdit:
			value_str = widget.text

		code = code.replace("{%s}" % param_name, value_str)

	# Handle container blocks with children
	if is_container and code.find("{children}") != -1:
		var child_code := ""
		for child in child_blocks:
			child_code += "    " + child.to_code() + "\n"
		code = code.replace("{children}", child_code)

	return code


## Returns the current parameter values as a Dictionary
func get_param_values() -> Dictionary:
	var values := {}
	for param_name in _param_widgets:
		var widget = _param_widgets[param_name]
		if widget is OptionButton:
			values[param_name] = widget.get_item_text(widget.selected)
		elif widget is SpinBox:
			values[param_name] = int(widget.value)
		elif widget is LineEdit:
			values[param_name] = widget.text
	return values


func _on_param_changed(_index: int) -> void:
	block_changed.emit()


func _on_spin_changed(_value: float) -> void:
	block_changed.emit()


func _on_text_param_changed(_text: String) -> void:
	block_changed.emit()


func _on_remove_pressed() -> void:
	block_remove_requested.emit(self)


func _on_param_focus_entered(param_name: String) -> void:
	# Signal that a place_building param is focused (for coordinate overlay)
	if block_id == "place_building":
		var values := get_param_values()
		# Use group to notify the coordinate overlay
		get_tree().call_group("coord_overlay", "show_overlay", values.get("col", 0), values.get("row", 0))


func _on_param_focus_exited(param_name: String) -> void:
	if block_id == "place_building":
		get_tree().call_group("coord_overlay", "hide_overlay")

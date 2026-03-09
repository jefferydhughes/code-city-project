extends CodeEdit

# Machi Koro-inspired warm UI theme for CodeCity editor.
# Includes loop visualization support for Mission 2.

var highlighter: CodeHighlighter

# -- Palette --
const COLOR_BG := Color("#FAF7F2")            # Warm parchment
const COLOR_CURRENT_LINE := Color("#EDE6DB")   # Soft highlight
const COLOR_PANEL_BG := Color("#F4EFE7")       # Panel background
const COLOR_TEXT := Color("#4A5568")            # Soft charcoal
const COLOR_TEAL := Color("#43A7BE")            # Calm teal (buttons/headers)
const COLOR_AMBER := Color("#E38B59")           # Soft amber (errors/strings)
const COLOR_SAGE := Color("#2A9D8F")            # Sage green (hints/success/API)
const COLOR_KEYWORD := Color("#327A99")         # Calm blue
const COLOR_COMMENT := Color("#A0AEC0")         # Light gray
const COLOR_NUMBER := Color("#9C6B3C")          # Warm brown
const COLOR_BORDER := Color("#EDE6DB")          # Border tone
const COLOR_WHITE := Color("#FFFFFF")
const COLOR_LOOP_HIGHLIGHT := Color("#EDE6DB")  # Loop body highlight

var _loop_highlight_tween: Tween = null


func _ready():
	highlighter = CodeHighlighter.new()

	# -- Syntax colors (warm tones) --
	highlighter.number_color = COLOR_NUMBER
	highlighter.symbol_color = Color("#7A8599")
	highlighter.function_color = COLOR_SAGE
	highlighter.member_variable_color = Color("#6B8E7B")

	# -- Keywords (calm blue) --
	var keywords := [
		"if", "elif", "else", "for", "while", "match", "break", "continue",
		"pass", "return", "class", "class_name", "extends", "is", "in",
		"as", "self", "signal", "func", "static", "const", "enum",
		"var", "onready", "export", "setget", "tool", "yield",
		"preload", "load", "await", "super",
		"and", "or", "not", "true", "false", "null",
		"do", "end", "then", "function", "local",
	]
	for kw in keywords:
		highlighter.add_keyword_color(kw, COLOR_KEYWORD)

	# -- Type keywords --
	var type_keywords := [
		"void", "int", "float", "bool", "String",
		"Vector2", "Vector3", "Vector2i", "Vector3i",
		"Color", "NodePath", "Array", "Dictionary",
		"Node", "Node2D", "Node3D", "Control", "Resource",
	]
	for tw in type_keywords:
		highlighter.add_keyword_color(tw, COLOR_KEYWORD)

	# -- API function keywords (sage teal) --
	var api_functions := [
		"place_building", "remove_building", "move_camera",
		"place_road", "place_tree", "place_house",
	]
	for fn in api_functions:
		highlighter.add_keyword_color(fn, COLOR_SAGE)

	# -- Regions --
	highlighter.add_color_region("#", "", COLOR_COMMENT, true)
	highlighter.add_color_region("--", "", COLOR_COMMENT, true)
	highlighter.add_color_region("\"", "\"", COLOR_AMBER, false)
	highlighter.add_color_region("'", "'", COLOR_AMBER, false)

	syntax_highlighter = highlighter

	# -- Editor theme (warm parchment) --
	add_theme_color_override("background_color", COLOR_BG)
	add_theme_color_override("font_color", COLOR_TEXT)
	add_theme_color_override("line_number_color", COLOR_COMMENT)
	add_theme_color_override("caret_color", Color("#4A5568"))
	add_theme_color_override("current_line_color", COLOR_CURRENT_LINE)
	add_theme_color_override("selection_color", Color("#C6DBE4", 0.45))
	add_theme_color_override("word_highlighted_color", Color("#C6DBE4", 0.3))
	add_theme_color_override("brace_mismatch_color", COLOR_AMBER)

	# -- CodeEdit border --
	var code_border := StyleBoxFlat.new()
	code_border.bg_color = COLOR_BG
	code_border.border_color = COLOR_BORDER
	code_border.set_border_width_all(1)
	code_border.set_corner_radius_all(6)
	code_border.set_content_margin_all(8)
	add_theme_stylebox_override("normal", code_border)

	# -- Style buttons and panels --
	_style_buttons()
	_style_feedback_panel()
	_style_header()

	# Connect buttons
	var run_btn = get_parent().get_node("Header/HBox/RunButton")
	var clear_btn = get_parent().get_node("Header/HBox/ClearButton")

	if run_btn:
		run_btn.pressed.connect(_on_run_pressed)
	if clear_btn:
		clear_btn.pressed.connect(_on_clear_pressed)

	# Connect to CodeRunner for loop visualization
	if CodeRunner:
		CodeRunner.loop_iteration.connect(_on_loop_iteration)
		CodeRunner.code_finished.connect(_on_code_finished)
		CodeRunner.code_error.connect(_on_code_error_received)


func _style_buttons():
	var run_btn: Button = get_parent().get_node_or_null("Header/HBox/RunButton")
	var clear_btn: Button = get_parent().get_node_or_null("Header/HBox/ClearButton")

	if run_btn:
		# Run button: teal bg, white text
		var run_normal := StyleBoxFlat.new()
		run_normal.bg_color = COLOR_TEAL
		run_normal.set_corner_radius_all(6)
		run_normal.set_content_margin_all(8)
		run_btn.add_theme_stylebox_override("normal", run_normal)

		var run_hover := StyleBoxFlat.new()
		run_hover.bg_color = COLOR_TEAL.lightened(0.1)
		run_hover.set_corner_radius_all(6)
		run_hover.set_content_margin_all(8)
		run_btn.add_theme_stylebox_override("hover", run_hover)

		var run_pressed := StyleBoxFlat.new()
		run_pressed.bg_color = COLOR_TEAL.darkened(0.1)
		run_pressed.set_corner_radius_all(6)
		run_pressed.set_content_margin_all(8)
		run_btn.add_theme_stylebox_override("pressed", run_pressed)

		run_btn.add_theme_color_override("font_color", COLOR_WHITE)
		run_btn.add_theme_color_override("font_hover_color", COLOR_WHITE)
		run_btn.add_theme_color_override("font_pressed_color", COLOR_WHITE)

	if clear_btn:
		# Clear button: warm bg, charcoal text
		var clear_normal := StyleBoxFlat.new()
		clear_normal.bg_color = COLOR_CURRENT_LINE
		clear_normal.set_corner_radius_all(6)
		clear_normal.set_content_margin_all(8)
		clear_btn.add_theme_stylebox_override("normal", clear_normal)

		var clear_hover := StyleBoxFlat.new()
		clear_hover.bg_color = COLOR_CURRENT_LINE.darkened(0.05)
		clear_hover.set_corner_radius_all(6)
		clear_hover.set_content_margin_all(8)
		clear_btn.add_theme_stylebox_override("hover", clear_hover)

		var clear_pressed := StyleBoxFlat.new()
		clear_pressed.bg_color = COLOR_CURRENT_LINE.darkened(0.1)
		clear_pressed.set_corner_radius_all(6)
		clear_pressed.set_content_margin_all(8)
		clear_btn.add_theme_stylebox_override("pressed", clear_pressed)

		clear_btn.add_theme_color_override("font_color", COLOR_TEXT)
		clear_btn.add_theme_color_override("font_hover_color", COLOR_TEXT)
		clear_btn.add_theme_color_override("font_pressed_color", COLOR_TEXT)


func _style_feedback_panel():
	var feedback_panel = get_parent().get_node_or_null("FeedbackPanel")
	if not feedback_panel:
		return

	# White bg with shadow, rounded corners
	var fb_style := StyleBoxFlat.new()
	fb_style.bg_color = COLOR_WHITE
	fb_style.set_corner_radius_all(8)
	fb_style.set_content_margin_all(12)
	fb_style.shadow_color = Color(0, 0, 0, 0.12)
	fb_style.shadow_size = 4
	fb_style.shadow_offset = Vector2(0, 2)
	feedback_panel.add_theme_stylebox_override("panel", fb_style)

	var fb_label: RichTextLabel = feedback_panel.get_node_or_null("FeedbackLabel")
	if fb_label:
		fb_label.add_theme_color_override("default_color", COLOR_TEXT)


func _style_header():
	var header = get_parent().get_node_or_null("Header")
	if not header:
		return

	# Mission header: teal bg, white text
	var header_style := StyleBoxFlat.new()
	header_style.bg_color = COLOR_TEAL
	header_style.set_corner_radius_all(6)
	header_style.set_content_margin_all(6)
	header_style.content_margin_left = 12
	header_style.content_margin_right = 8
	header.add_theme_stylebox_override("panel", header_style)

	var label: Label = header.get_node_or_null("HBox/Label")
	if label:
		label.add_theme_color_override("font_color", COLOR_WHITE)


# -- Loop Visualization --

func _on_loop_iteration(var_name: String, value: int, _total: int) -> void:
	# Find the loop body lines and highlight them
	_highlight_loop_body()


func _highlight_loop_body() -> void:
	# Find lines between "for...do" and "end" and pulse highlight them
	var lines := text.split("\n")
	var in_loop := false
	var body_start := -1
	var body_end := -1

	for i in range(lines.size()):
		var line := lines[i].strip_edges().to_lower()
		if line.begins_with("for ") and line.ends_with(" do"):
			in_loop = true
			body_start = i + 1
		elif in_loop and line == "end":
			body_end = i - 1
			break

	if body_start >= 0 and body_end >= body_start:
		# Pulse the background of body lines
		if _loop_highlight_tween:
			_loop_highlight_tween.kill()

		# Set a bright highlight then fade back
		add_theme_color_override("current_line_color", Color(COLOR_LOOP_HIGHLIGHT, 0.8))
		_loop_highlight_tween = create_tween()
		_loop_highlight_tween.tween_property(self, "theme_override_colors/current_line_color", COLOR_CURRENT_LINE, 0.5)


func _on_code_finished() -> void:
	_clear_loop_highlights()


func _on_code_error_received(_message: String, _line_num: int) -> void:
	_clear_loop_highlights()


func _clear_loop_highlights() -> void:
	if _loop_highlight_tween:
		_loop_highlight_tween.kill()
		_loop_highlight_tween = null
	add_theme_color_override("current_line_color", COLOR_CURRENT_LINE)


# -- Button handlers --

func _on_run_pressed():
	print("--- CodeCity Script Output ---")
	print(text)
	print("--- End Script ---")
	# Dispatch to CodeRunner autoload
	if CodeRunner:
		CodeRunner.run_code(text)


func _on_clear_pressed():
	text = ""

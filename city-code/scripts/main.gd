extends Control

# Main scene controller — wires MissionManager, CodeRunner, and UI together.
# Applies Machi Koro-inspired warm theme to dialogue/celebration panels.
# Includes Block Coding Mode and Epic (Text) Mode.

@onready var code_edit: CodeEdit = $HSplitContainer/CodeEditorPanel/VBoxContainer/CodeEdit
@onready var feedback_label: RichTextLabel = $HSplitContainer/CodeEditorPanel/VBoxContainer/FeedbackPanel/FeedbackLabel
@onready var feedback_panel: PanelContainer = $HSplitContainer/CodeEditorPanel/VBoxContainer/FeedbackPanel
@onready var dialogue_panel: PanelContainer = $HSplitContainer/SubViewportContainer/SubViewport/CanvasLayer/DialoguePanel
@onready var dialogue_label: RichTextLabel = $HSplitContainer/SubViewportContainer/SubViewport/CanvasLayer/DialoguePanel/MarginContainer/VBoxContainer/DialogueLabel
@onready var dialogue_name: Label = $HSplitContainer/SubViewportContainer/SubViewport/CanvasLayer/DialoguePanel/MarginContainer/VBoxContainer/HeaderBar/NameLabel
@onready var dialogue_button: Button = $HSplitContainer/SubViewportContainer/SubViewport/CanvasLayer/DialoguePanel/MarginContainer/VBoxContainer/DialogueButton
@onready var celebration_panel: PanelContainer = $HSplitContainer/SubViewportContainer/SubViewport/CanvasLayer/CelebrationPanel
@onready var celebration_label: Label = $HSplitContainer/SubViewportContainer/SubViewport/CanvasLayer/CelebrationPanel/MarginContainer/VBoxContainer/CelebrationLabel
@onready var celebration_button: Button = $HSplitContainer/SubViewportContainer/SubViewport/CanvasLayer/CelebrationPanel/MarginContainer/VBoxContainer/CelebrationButton
@onready var gridmap: GridMap = $HSplitContainer/SubViewportContainer/SubViewport/GridMap
@onready var code_editor_panel: PanelContainer = $HSplitContainer/CodeEditorPanel
@onready var canvas_layer: CanvasLayer = $HSplitContainer/SubViewportContainer/SubViewport/CanvasLayer

# -- Palette --
const COLOR_TEAL := Color("#43A7BE")
const COLOR_WHITE := Color("#FFFFFF")
const COLOR_TEXT := Color("#4A5568")
const COLOR_AMBER := Color("#E38B59")
const COLOR_SAGE := Color("#2A9D8F")
const COLOR_PANEL_BG := Color("#F4EFE7")
const COLOR_BG := Color("#FAF7F2")
const COLOR_HIGHLIGHT := Color("#EDE6DB")
const COLOR_KEYWORD := Color("#327A99")

var _autotype_tween: Tween = null
var _feedback_style: StyleBoxFlat = null

# Dynamic UI nodes — 3D overlay
var notification_banner: PanelContainer = null
var notification_label: Label = null
var loop_counter: Label = null
var bonus_panel: PanelContainer = null
var bonus_label: RichTextLabel = null
var bonus_try_btn: Button = null
var bonus_continue_btn: Button = null

# Block coding mode nodes
var mode_toggle_bar: HBoxContainer = null
var blocks_tab_btn: Button = null
var text_tab_btn: Button = null
var blocks_scroll: ScrollContainer = null
var blocks_vbox: VBoxContainer = null
var epic_banner: PanelContainer = null
var _blocks_mode := true

# Tutorial panel (HudMission)
var tutorial_panel: HudMission = null

# State
var _mission_2_intro_shown := false
var _celebration_callback: Callable = Callable()


func _ready() -> void:
	# Create dynamic UI nodes on the 3D canvas
	_create_notification_banner()
	_create_loop_counter()
	_create_bonus_panel()

	# Create block coding mode UI in the code editor panel
	_create_mode_toggle()
	_create_blocks_panel()
	_create_epic_banner()
	_create_tutorial_panel()
	_apply_blocks_mode()  # Blocks mode is default

	# Apply warm theme to all panels
	_theme_code_editor_panel()
	_theme_dialogue_panel()
	_theme_celebration_panel()

	# Connect ALL signals BEFORE setup so mission_loaded fires correctly
	MissionManager.feedback.connect(_on_feedback)
	MissionManager.error.connect(_on_error)
	MissionManager.mission_complete.connect(_on_mission_complete)
	MissionManager.hint_available.connect(_on_hint)
	MissionManager.mission_loaded.connect(_on_mission_loaded)
	MissionManager.mission_2_unlocked.connect(_on_mission_2_unlocked)
	MissionManager.bonus_complete.connect(_on_bonus_complete)
	MissionManager.step_advanced.connect(_on_step_advanced)
	MissionManager.autotype_solution.connect(_on_autotype_solution)

	if CodeRunner:
		CodeRunner.loop_iteration.connect(_on_loop_iteration)
		CodeRunner.code_finished.connect(_on_code_finished)

	dialogue_button.pressed.connect(_on_dialogue_dismiss)
	celebration_button.pressed.connect(_on_celebration_dismiss)

	# Setup MissionManager AFTER signals are connected
	MissionManager.setup(gridmap)


# ========================================================================
#  BLOCK CODING MODE
# ========================================================================

func _create_mode_toggle() -> void:
	var vbox: VBoxContainer = code_editor_panel.get_node("VBoxContainer")

	mode_toggle_bar = HBoxContainer.new()
	mode_toggle_bar.name = "ModeToggleBar"
	mode_toggle_bar.add_theme_constant_override("separation", 0)
	vbox.add_child(mode_toggle_bar)
	vbox.move_child(mode_toggle_bar, 1)  # After Header

	blocks_tab_btn = Button.new()
	blocks_tab_btn.text = "  Blocks  "
	blocks_tab_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	blocks_tab_btn.pressed.connect(_on_blocks_tab)
	mode_toggle_bar.add_child(blocks_tab_btn)

	text_tab_btn = Button.new()
	text_tab_btn.text = "  Text  "
	text_tab_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_tab_btn.pressed.connect(_on_text_tab)
	mode_toggle_bar.add_child(text_tab_btn)


func _create_blocks_panel() -> void:
	var vbox: VBoxContainer = code_editor_panel.get_node("VBoxContainer")

	# Use a PanelContainer as the blocks area (no ScrollContainer nesting issues)
	blocks_scroll = ScrollContainer.new()
	blocks_scroll.name = "BlocksScroll"
	blocks_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	blocks_scroll.size_flags_stretch_ratio = 3.0
	blocks_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(blocks_scroll)
	vbox.move_child(blocks_scroll, 2)  # After ModeToggleBar

	blocks_vbox = VBoxContainer.new()
	blocks_vbox.name = "BlocksVBox"
	blocks_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	blocks_vbox.add_theme_constant_override("separation", 12)

	# Style the VBoxContainer with a background panel look
	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = COLOR_BG
	bg_style.set_corner_radius_all(6)
	bg_style.set_content_margin_all(16)
	bg_style.border_color = COLOR_HIGHLIGHT
	bg_style.set_border_width_all(1)
	blocks_vbox.add_theme_stylebox_override("panel", bg_style)

	blocks_scroll.add_child(blocks_vbox)


func _create_epic_banner() -> void:
	var vbox: VBoxContainer = code_editor_panel.get_node("VBoxContainer")

	epic_banner = PanelContainer.new()
	epic_banner.name = "EpicModeBanner"
	epic_banner.visible = false
	vbox.add_child(epic_banner)
	vbox.move_child(epic_banner, 3)  # After BlocksScroll

	var banner_style := StyleBoxFlat.new()
	banner_style.bg_color = COLOR_TEAL
	banner_style.set_corner_radius_all(6)
	banner_style.set_content_margin_all(6)
	epic_banner.add_theme_stylebox_override("panel", banner_style)

	var banner_label := Label.new()
	banner_label.text = "Epic Mode — you're coding like a pro!"
	banner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner_label.add_theme_color_override("font_color", COLOR_WHITE)
	epic_banner.add_child(banner_label)


func _create_tutorial_panel() -> void:
	var vbox: VBoxContainer = code_editor_panel.get_node("VBoxContainer")

	tutorial_panel = HudMission.new()
	tutorial_panel.name = "TutorialPanel"
	tutorial_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tutorial_panel.size_flags_stretch_ratio = 1.0
	vbox.add_child(tutorial_panel)
	# Move it before the FeedbackPanel (insert after epic banner position)
	var feedback_idx := feedback_panel.get_index()
	vbox.move_child(tutorial_panel, feedback_idx)


func _on_blocks_tab() -> void:
	_blocks_mode = true
	_apply_blocks_mode()


func _on_text_tab() -> void:
	_blocks_mode = false
	_apply_blocks_mode()


func _apply_blocks_mode() -> void:
	if not blocks_scroll or not code_edit or not epic_banner:
		return

	blocks_scroll.visible = _blocks_mode
	epic_banner.visible = not _blocks_mode
	code_edit.visible = not _blocks_mode

	# Style active/inactive tabs
	_style_tab_button(blocks_tab_btn, _blocks_mode)
	_style_tab_button(text_tab_btn, not _blocks_mode)


func _style_tab_button(btn: Button, active: bool) -> void:
	if not btn:
		return

	var style := StyleBoxFlat.new()
	if active:
		style.bg_color = COLOR_TEAL
		btn.add_theme_color_override("font_color", COLOR_WHITE)
		btn.add_theme_color_override("font_hover_color", COLOR_WHITE)
		btn.add_theme_color_override("font_pressed_color", COLOR_WHITE)
	else:
		style.bg_color = COLOR_HIGHLIGHT
		btn.add_theme_color_override("font_color", COLOR_TEXT)
		btn.add_theme_color_override("font_hover_color", COLOR_TEXT)
		btn.add_theme_color_override("font_pressed_color", COLOR_TEXT)

	style.set_corner_radius_all(6)
	style.set_content_margin_all(8)
	btn.add_theme_stylebox_override("normal", style)

	var hover := style.duplicate()
	if active:
		hover.bg_color = COLOR_TEAL.lightened(0.08)
	else:
		hover.bg_color = COLOR_HIGHLIGHT.darkened(0.05)
	btn.add_theme_stylebox_override("hover", hover)

	var pressed := style.duplicate()
	if active:
		pressed.bg_color = COLOR_TEAL.darkened(0.08)
	else:
		pressed.bg_color = COLOR_HIGHLIGHT.darkened(0.1)
	btn.add_theme_stylebox_override("pressed", pressed)


func _update_blocks_for_mission(mission_id: String) -> void:
	if not blocks_vbox:
		return

	# Clear existing blocks
	for child in blocks_vbox.get_children():
		child.queue_free()

	# Add instruction label at top
	var instr := Label.new()
	instr.add_theme_color_override("font_color", COLOR_TEXT)
	instr.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	blocks_vbox.add_child(instr)

	if mission_id == "m1_first_house":
		instr.text = "Click the block below to add it to your code, then press Run!"

		# Single "place house" block
		var house_code := "place_building(\"house\", 5, 5)\n"
		var block := _create_action_block("place house at (5, 5)", house_code)
		blocks_vbox.add_child(block)

	elif mission_id == "m2_row_of_homes":
		instr.text = "Click the block to build 5 houses in a row using a loop!"

		# Combined repeat + house block (nested visual)
		var loop_code := "for i = 1, 5 do\n    place_building(\"house\", i, 2)\nend\n"
		var nested_block := _create_loop_block("repeat 5 times", "place house at (i, 2)", loop_code)
		blocks_vbox.add_child(nested_block)

		# Spacer
		var spacer := Control.new()
		spacer.custom_minimum_size = Vector2(0, 8)
		blocks_vbox.add_child(spacer)

		# Also individual house block for experimentation
		var house_code := "place_building(\"house\", 5, 2)\n"
		var single_block := _create_action_block("place house at (5, 2)", house_code)
		blocks_vbox.add_child(single_block)


func _create_action_block(label_text: String, code: String) -> Button:
	# Simple styled button that looks like a Scratch action block
	var btn := Button.new()
	btn.text = "  " + label_text
	btn.custom_minimum_size = Vector2(0, 48)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	# Amber block style (like Scratch motion blocks)
	var normal := StyleBoxFlat.new()
	normal.bg_color = COLOR_AMBER
	normal.set_corner_radius_all(8)
	normal.set_content_margin_all(12)
	normal.shadow_color = Color(0, 0, 0, 0.10)
	normal.shadow_size = 2
	normal.shadow_offset = Vector2(0, 1)
	btn.add_theme_stylebox_override("normal", normal)

	var hover := StyleBoxFlat.new()
	hover.bg_color = COLOR_AMBER.lightened(0.12)
	hover.set_corner_radius_all(8)
	hover.set_content_margin_all(12)
	hover.shadow_color = Color(0, 0, 0, 0.12)
	hover.shadow_size = 3
	hover.shadow_offset = Vector2(0, 2)
	btn.add_theme_stylebox_override("hover", hover)

	var pressed := StyleBoxFlat.new()
	pressed.bg_color = COLOR_AMBER.darkened(0.1)
	pressed.set_corner_radius_all(8)
	pressed.set_content_margin_all(12)
	btn.add_theme_stylebox_override("pressed", pressed)

	btn.add_theme_color_override("font_color", COLOR_WHITE)
	btn.add_theme_color_override("font_hover_color", COLOR_WHITE)
	btn.add_theme_color_override("font_pressed_color", COLOR_WHITE)

	btn.pressed.connect(_on_block_clicked.bind(code, btn))
	return btn


func _create_loop_block(loop_text: String, inner_text: String, code: String) -> VBoxContainer:
	# Wrapper VBox that visually nests blocks like Scratch
	var wrapper := VBoxContainer.new()
	wrapper.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	wrapper.add_theme_constant_override("separation", 0)

	# Top part: blue "repeat" header button
	var top_btn := Button.new()
	top_btn.text = "  " + loop_text
	top_btn.custom_minimum_size = Vector2(0, 44)
	top_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	top_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	var top_style := StyleBoxFlat.new()
	top_style.bg_color = COLOR_KEYWORD
	top_style.corner_radius_top_left = 8
	top_style.corner_radius_top_right = 8
	top_style.corner_radius_bottom_left = 0
	top_style.corner_radius_bottom_right = 0
	top_style.set_content_margin_all(12)
	top_style.shadow_color = Color(0, 0, 0, 0.10)
	top_style.shadow_size = 2
	top_btn.add_theme_stylebox_override("normal", top_style)

	var top_hover := top_style.duplicate()
	top_hover.bg_color = COLOR_KEYWORD.lightened(0.12)
	top_btn.add_theme_stylebox_override("hover", top_hover)

	var top_pressed := top_style.duplicate()
	top_pressed.bg_color = COLOR_KEYWORD.darkened(0.1)
	top_btn.add_theme_stylebox_override("pressed", top_pressed)

	top_btn.add_theme_color_override("font_color", COLOR_WHITE)
	top_btn.add_theme_color_override("font_hover_color", COLOR_WHITE)
	top_btn.add_theme_color_override("font_pressed_color", COLOR_WHITE)
	top_btn.pressed.connect(_on_block_clicked.bind(code, wrapper))
	wrapper.add_child(top_btn)

	# Middle: blue background panel with indented amber inner block
	var mid_panel := PanelContainer.new()
	mid_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var mid_style := StyleBoxFlat.new()
	mid_style.bg_color = COLOR_KEYWORD
	mid_style.set_corner_radius_all(0)
	mid_style.content_margin_left = 20
	mid_style.content_margin_right = 12
	mid_style.content_margin_top = 4
	mid_style.content_margin_bottom = 4
	mid_panel.add_theme_stylebox_override("panel", mid_style)

	# Inner amber block (nested look)
	var inner_btn := Button.new()
	inner_btn.text = "  " + inner_text
	inner_btn.custom_minimum_size = Vector2(0, 40)
	inner_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inner_btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	inner_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	var inner_normal := StyleBoxFlat.new()
	inner_normal.bg_color = COLOR_AMBER
	inner_normal.set_corner_radius_all(6)
	inner_normal.set_content_margin_all(10)
	inner_btn.add_theme_stylebox_override("normal", inner_normal)

	var inner_hover := inner_normal.duplicate()
	inner_hover.bg_color = COLOR_AMBER.lightened(0.12)
	inner_btn.add_theme_stylebox_override("hover", inner_hover)

	var inner_pressed := inner_normal.duplicate()
	inner_pressed.bg_color = COLOR_AMBER.darkened(0.1)
	inner_btn.add_theme_stylebox_override("pressed", inner_pressed)

	inner_btn.add_theme_color_override("font_color", COLOR_WHITE)
	inner_btn.add_theme_color_override("font_hover_color", COLOR_WHITE)
	inner_btn.add_theme_color_override("font_pressed_color", COLOR_WHITE)
	inner_btn.pressed.connect(_on_block_clicked.bind(code, wrapper))
	mid_panel.add_child(inner_btn)
	wrapper.add_child(mid_panel)

	# Bottom: blue "end" footer
	var bottom := PanelContainer.new()
	bottom.custom_minimum_size = Vector2(0, 16)
	bottom.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var bottom_style := StyleBoxFlat.new()
	bottom_style.bg_color = COLOR_KEYWORD
	bottom_style.corner_radius_top_left = 0
	bottom_style.corner_radius_top_right = 0
	bottom_style.corner_radius_bottom_left = 8
	bottom_style.corner_radius_bottom_right = 8
	bottom_style.set_content_margin_all(4)
	bottom_style.shadow_color = Color(0, 0, 0, 0.10)
	bottom_style.shadow_size = 2
	bottom_style.shadow_offset = Vector2(0, 1)
	bottom.add_theme_stylebox_override("panel", bottom_style)
	wrapper.add_child(bottom)

	return wrapper


func _on_block_clicked(code: String, block_node: Control) -> void:
	# Insert code into the hidden CodeEdit
	if code_edit:
		code_edit.text = code

	# Flash animation on the block
	if block_node:
		var tween := create_tween()
		tween.tween_property(block_node, "modulate", Color(1.4, 1.4, 1.4, 1.0), 0.08)
		tween.tween_property(block_node, "modulate", Color.WHITE, 0.15)

	_set_feedback_border(COLOR_SAGE)
	_show_feedback("Code added! Press Run to build.", COLOR_SAGE)


# ========================================================================
#  DYNAMIC UI CREATION (3D canvas overlay)
# ========================================================================

func _create_notification_banner() -> void:
	notification_banner = PanelContainer.new()
	notification_banner.name = "NotificationBanner"
	notification_banner.visible = false
	canvas_layer.add_child(notification_banner)

	notification_banner.set_anchors_preset(Control.PRESET_TOP_WIDE)
	notification_banner.offset_top = -60
	notification_banner.offset_bottom = 0

	var style := StyleBoxFlat.new()
	style.bg_color = COLOR_TEAL
	style.set_corner_radius_all(0)
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.set_content_margin_all(12)
	style.shadow_color = Color(0, 0, 0, 0.10)
	style.shadow_size = 4
	style.shadow_offset = Vector2(0, 2)
	notification_banner.add_theme_stylebox_override("panel", style)

	notification_label = Label.new()
	notification_label.name = "NotificationLabel"
	notification_label.text = "Mission 2 Unlocked!"
	notification_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notification_label.add_theme_color_override("font_color", COLOR_WHITE)
	notification_banner.add_child(notification_label)


func _create_loop_counter() -> void:
	loop_counter = Label.new()
	loop_counter.name = "LoopCounter"
	loop_counter.visible = false
	loop_counter.text = ""
	loop_counter.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	loop_counter.add_theme_color_override("font_color", COLOR_TEXT)
	canvas_layer.add_child(loop_counter)

	loop_counter.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	loop_counter.offset_left = -220
	loop_counter.offset_top = 10
	loop_counter.offset_right = -10
	loop_counter.offset_bottom = 40

	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(COLOR_BG, 0.9)
	bg.set_corner_radius_all(8)
	bg.set_content_margin_all(8)
	bg.shadow_color = Color(0, 0, 0, 0.10)
	bg.shadow_size = 2
	loop_counter.add_theme_stylebox_override("normal", bg)


func _create_bonus_panel() -> void:
	bonus_panel = PanelContainer.new()
	bonus_panel.name = "BonusChallengePanel"
	bonus_panel.visible = false
	canvas_layer.add_child(bonus_panel)

	bonus_panel.set_anchors_preset(Control.PRESET_CENTER)
	bonus_panel.offset_left = -220
	bonus_panel.offset_top = -120
	bonus_panel.offset_right = 220
	bonus_panel.offset_bottom = 120

	var style := StyleBoxFlat.new()
	style.bg_color = COLOR_WHITE
	style.set_corner_radius_all(12)
	style.set_content_margin_all(0)
	style.shadow_color = Color(0, 0, 0, 0.15)
	style.shadow_size = 8
	style.shadow_offset = Vector2(0, 4)
	bonus_panel.add_theme_stylebox_override("panel", style)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	bonus_panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(vbox)

	var star_label := Label.new()
	star_label.text = "BONUS CHALLENGE"
	star_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	star_label.add_theme_color_override("font_color", COLOR_TEAL)
	vbox.add_child(star_label)

	bonus_label = RichTextLabel.new()
	bonus_label.bbcode_enabled = true
	bonus_label.fit_content = true
	bonus_label.text = "Can you build [b]TWO[/b] rows of houses?\nOne at y=2 and one at y=4?"
	bonus_label.add_theme_color_override("default_color", COLOR_TEXT)
	vbox.add_child(bonus_label)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 8)
	vbox.add_child(spacer)

	var hbox := HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(hbox)

	bonus_try_btn = Button.new()
	bonus_try_btn.text = " Try Bonus Challenge "
	_style_teal_button(bonus_try_btn)
	bonus_try_btn.pressed.connect(_on_bonus_try)
	hbox.add_child(bonus_try_btn)

	var spacer2 := Control.new()
	spacer2.custom_minimum_size = Vector2(12, 0)
	hbox.add_child(spacer2)

	bonus_continue_btn = Button.new()
	bonus_continue_btn.text = " Continue to Mission 3 "
	_style_light_button(bonus_continue_btn)
	bonus_continue_btn.pressed.connect(_on_bonus_continue)
	hbox.add_child(bonus_continue_btn)


# ========================================================================
#  THEME FUNCTIONS
# ========================================================================

func _theme_code_editor_panel() -> void:
	if not code_editor_panel:
		return
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = COLOR_PANEL_BG
	panel_style.set_corner_radius_all(8)
	panel_style.set_content_margin_all(8)
	code_editor_panel.add_theme_stylebox_override("panel", panel_style)


func _theme_dialogue_panel() -> void:
	if not dialogue_panel:
		return

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = COLOR_WHITE
	panel_style.set_corner_radius_all(12)
	panel_style.set_content_margin_all(0)
	panel_style.shadow_color = Color(0, 0, 0, 0.15)
	panel_style.shadow_size = 8
	panel_style.shadow_offset = Vector2(0, 4)
	dialogue_panel.add_theme_stylebox_override("panel", panel_style)

	if dialogue_name:
		var header_bar: PanelContainer = dialogue_name.get_parent()
		var hbar_style := StyleBoxFlat.new()
		hbar_style.bg_color = COLOR_TEAL
		hbar_style.corner_radius_top_left = 10
		hbar_style.corner_radius_top_right = 10
		hbar_style.set_content_margin_all(8)
		hbar_style.content_margin_left = 12
		header_bar.add_theme_stylebox_override("panel", hbar_style)
		dialogue_name.add_theme_color_override("font_color", COLOR_WHITE)

	if dialogue_label:
		dialogue_label.add_theme_color_override("default_color", COLOR_TEXT)

	if dialogue_button:
		_style_teal_button(dialogue_button)


func _theme_celebration_panel() -> void:
	if not celebration_panel:
		return

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = COLOR_WHITE
	panel_style.set_corner_radius_all(12)
	panel_style.set_content_margin_all(0)
	panel_style.shadow_color = Color(0, 0, 0, 0.15)
	panel_style.shadow_size = 8
	panel_style.shadow_offset = Vector2(0, 4)
	celebration_panel.add_theme_stylebox_override("panel", panel_style)

	if celebration_label:
		celebration_label.add_theme_color_override("font_color", COLOR_TEAL)

	if celebration_button:
		_style_teal_button(celebration_button)


func _style_teal_button(btn: Button) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = COLOR_TEAL
	normal.set_corner_radius_all(8)
	normal.set_content_margin_all(10)
	btn.add_theme_stylebox_override("normal", normal)

	var hover := StyleBoxFlat.new()
	hover.bg_color = COLOR_TEAL.lightened(0.1)
	hover.set_corner_radius_all(8)
	hover.set_content_margin_all(10)
	btn.add_theme_stylebox_override("hover", hover)

	var pressed := StyleBoxFlat.new()
	pressed.bg_color = COLOR_TEAL.darkened(0.1)
	pressed.set_corner_radius_all(8)
	pressed.set_content_margin_all(10)
	btn.add_theme_stylebox_override("pressed", pressed)

	btn.add_theme_color_override("font_color", COLOR_WHITE)
	btn.add_theme_color_override("font_hover_color", COLOR_WHITE)
	btn.add_theme_color_override("font_pressed_color", COLOR_WHITE)


func _style_light_button(btn: Button) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = COLOR_PANEL_BG
	normal.set_corner_radius_all(8)
	normal.set_content_margin_all(10)
	btn.add_theme_stylebox_override("normal", normal)

	var hover := StyleBoxFlat.new()
	hover.bg_color = COLOR_PANEL_BG.darkened(0.05)
	hover.set_corner_radius_all(8)
	hover.set_content_margin_all(10)
	btn.add_theme_stylebox_override("hover", hover)

	var pressed := StyleBoxFlat.new()
	pressed.bg_color = COLOR_PANEL_BG.darkened(0.1)
	pressed.set_corner_radius_all(8)
	pressed.set_content_margin_all(10)
	btn.add_theme_stylebox_override("pressed", pressed)

	btn.add_theme_color_override("font_color", COLOR_TEXT)
	btn.add_theme_color_override("font_hover_color", COLOR_TEXT)
	btn.add_theme_color_override("font_pressed_color", COLOR_TEXT)


func _set_feedback_border(color: Color) -> void:
	if not feedback_panel:
		return
	var style := StyleBoxFlat.new()
	style.bg_color = COLOR_WHITE
	style.set_corner_radius_all(8)
	style.set_content_margin_all(12)
	style.shadow_color = Color(0, 0, 0, 0.12)
	style.shadow_size = 4
	style.shadow_offset = Vector2(0, 2)
	style.border_color = color
	style.border_width_left = 4
	style.content_margin_left = 16
	feedback_panel.add_theme_stylebox_override("panel", style)


# ========================================================================
#  NOTIFICATION BANNER
# ========================================================================

func _show_notification(text: String, duration: float = 3.0) -> void:
	if not notification_banner or not notification_label:
		return
	notification_label.text = text
	notification_banner.visible = true
	notification_banner.offset_top = -60

	var tween := create_tween()
	tween.tween_property(notification_banner, "offset_top", 0.0, 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

	await get_tree().create_timer(duration).timeout

	var dismiss_tween := create_tween()
	dismiss_tween.tween_property(notification_banner, "offset_top", -60.0, 0.3).set_ease(Tween.EASE_IN)
	await dismiss_tween.finished
	notification_banner.visible = false


# ========================================================================
#  LOOP COUNTER
# ========================================================================

func _on_loop_iteration(var_name: String, value: int, total: int) -> void:
	if loop_counter:
		loop_counter.visible = true
		loop_counter.text = "Building house %d of %d..." % [value, total]


func _hide_loop_counter() -> void:
	if loop_counter:
		loop_counter.visible = false


func _on_code_finished() -> void:
	_hide_loop_counter()
	if MissionManager.current_mission_id == "m2_row_of_homes" and MissionManager.active_mission:
		if MissionManager.active_mission.has_method("check_bonus"):
			MissionManager.active_mission.check_bonus()


# ========================================================================
#  MISSION CALLBACKS
# ========================================================================

func _on_mission_loaded(mission: Node) -> void:
	var starter := MissionManager.get_starter_code()
	if starter != "" and code_edit:
		code_edit.text = starter

	# Update dialogue panel character name
	var char_name := MissionManager.get_character_name()
	if dialogue_name:
		dialogue_name.text = "  " + char_name

	_hide_loop_counter()

	# Update blocks for current mission
	_update_blocks_for_mission(MissionManager.current_mission_id)

	# Reset to blocks mode on new mission
	_blocks_mode = true
	_apply_blocks_mode()

	# Load first step into tutorial panel for mission 1
	if MissionManager.current_mission_id == "m1_first_house" and tutorial_panel:
		if mission.has_method("get_current_step"):
			tutorial_panel.load_step(mission.get_current_step())


func _on_step_advanced(step_id: int) -> void:
	# Update tutorial panel with new step
	if tutorial_panel:
		tutorial_panel.on_step_advanced(step_id)

	# Update code editor with starter code for the new step
	if MissionManager.active_mission and MissionManager.active_mission.has_method("get_step"):
		var step: Dictionary = MissionManager.active_mission.get_step(step_id)
		var starter: String = step.get("starter_code", "")
		if code_edit:
			code_edit.text = starter

	# Show step dialogue
	if MissionManager.active_mission and MissionManager.active_mission.has_method("get_step"):
		var step: Dictionary = MissionManager.active_mission.get_step(step_id)
		var dialogue: String = step.get("mayor_dialogue", "")
		if dialogue != "":
			_show_dialogue(dialogue)


func _on_autotype_solution(code_string: String) -> void:
	# Switch to text mode and autotype the solution
	_blocks_mode = false
	_apply_blocks_mode()
	_show_dialogue("Let me show you how it's done!")
	_autotype_code(code_string)


func _on_feedback(message: String) -> void:
	_set_feedback_border(COLOR_SAGE)
	_show_feedback(message, COLOR_SAGE)


func _on_error(message: String, _line_num: int) -> void:
	_set_feedback_border(COLOR_AMBER)
	_show_feedback(message + "\nFix it up and click Run again!", COLOR_AMBER)
	_hide_loop_counter()


func _on_mission_complete(mission_name: String) -> void:
	_hide_loop_counter()

	if MissionManager.current_mission_id == "m1_first_house":
		celebration_panel.visible = true
		celebration_label.text = "Mission Complete!"
		_set_feedback_border(COLOR_SAGE)
		_show_feedback("Amazing! You built your first house!", COLOR_SAGE)

	elif MissionManager.current_mission_id == "m2_row_of_homes":
		celebration_panel.visible = true
		celebration_label.text = "Mission Complete!"
		_set_feedback_border(COLOR_SAGE)
		_show_feedback("Amazing! You just built 5 houses with only 3 lines of code!\nThat's the power of loops!", COLOR_SAGE)
		_celebration_callback = Callable(self, "_show_bonus_challenge")


func _on_mission_2_unlocked() -> void:
	_show_notification("Mission 2 Unlocked!")


func _on_hint(hint_text: String, hint_number: int) -> void:
	if MissionManager.current_mission_id == "m1_first_house":
		# Show hint in the tutorial panel
		if tutorial_panel:
			tutorial_panel.show_hint()
		_show_dialogue(hint_text)
	elif MissionManager.current_mission_id == "m2_row_of_homes":
		if hint_number == 3:
			_show_dialogue("Let me show you how it's done!")
			_blocks_mode = false
			_apply_blocks_mode()
			_autotype_code("for i = 1, 5 do\n    place_building(\"house\", i, 2)\nend\n")
		else:
			_show_dialogue(hint_text)


func _on_bonus_complete() -> void:
	bonus_panel.visible = false
	celebration_panel.visible = true
	celebration_label.text = "Overachiever!"
	_set_feedback_border(COLOR_SAGE)
	_show_feedback("You built TWO rows of houses! You're a loop master!", COLOR_SAGE)


# ========================================================================
#  MISSION 2 TRANSITION
# ========================================================================

func _start_mission_2() -> void:
	celebration_panel.visible = false

	if dialogue_name:
		dialogue_name.text = "  Builder Bob"

	_show_dialogue("Great job on that first house! But look — five more families just arrived!\nWe need five houses in a row. Real coders use [b]LOOPS[/b] to avoid repetition.\nLet me show you how!")
	_mission_2_intro_shown = true


func _show_bonus_challenge() -> void:
	if bonus_panel and bonus_label:
		bonus_label.clear()
		bonus_label.append_text("[b]Can you build TWO rows of houses?[/b]\nOne at y=2 and one at y=4?")
		bonus_panel.visible = true


func _on_bonus_try() -> void:
	bonus_panel.visible = false
	if MissionManager.active_mission:
		MissionManager.active_mission.completed = false
		MissionManager.active_mission._placed_houses.clear()
	if gridmap:
		gridmap.clear()
		MissionManager._fill_grass()
	# Switch to text mode for the bonus
	_blocks_mode = false
	_apply_blocks_mode()
	if code_edit:
		code_edit.text = """-- BONUS: Build TWO rows of houses!
-- Row 1 at y=2, Row 2 at y=4

for i = 1, 5 do
    -- Build first row here
end

for i = 1, 5 do
    -- Build second row here
end
"""
	_set_feedback_border(COLOR_SAGE)
	_show_feedback("Bonus Challenge! Build 10 houses in 2 rows.", COLOR_SAGE)


func _on_bonus_continue() -> void:
	bonus_panel.visible = false
	_show_dialogue("Mission 3 is coming soon! Stay tuned, builder!")


# ========================================================================
#  UI HELPERS
# ========================================================================

func _show_feedback(message: String, color: Color) -> void:
	if feedback_label:
		feedback_label.clear()
		feedback_label.push_color(color)
		feedback_label.append_text(message)
		feedback_label.pop()


func _show_dialogue(bbcode_text: String) -> void:
	if dialogue_panel and dialogue_label:
		dialogue_label.clear()
		dialogue_label.append_text(bbcode_text)
		dialogue_panel.visible = true


func _on_dialogue_dismiss() -> void:
	dialogue_panel.visible = false

	if _mission_2_intro_shown:
		_mission_2_intro_shown = false
		MissionManager.load_mission_2()


func _on_celebration_dismiss() -> void:
	celebration_panel.visible = false

	if _celebration_callback.is_valid():
		var cb := _celebration_callback
		_celebration_callback = Callable()
		cb.call()

	if MissionManager.current_mission_id == "m1_first_house" and MissionManager.active_mission and MissionManager.active_mission.completed:
		await get_tree().create_timer(0.5).timeout
		_start_mission_2()


func _autotype_code(target_text: String) -> void:
	if not code_edit:
		return

	code_edit.text = ""

	if _autotype_tween:
		_autotype_tween.kill()

	_autotype_tween = create_tween()
	var current := ""

	for i in range(target_text.length()):
		var ch := target_text[i]
		current += ch
		var captured := current
		_autotype_tween.tween_callback(func(): code_edit.text = captured)
		_autotype_tween.tween_interval(0.06)

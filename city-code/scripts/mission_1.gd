class_name Mission1
extends Node

# Mission 1: Learn to Build — 10-Step Curriculum
# Students learn place_building() through progressive steps from
# explanation to guided coding to free-form challenges.

signal mission_completed
signal mission_feedback(message: String)
signal mission_hint(hint_text: String, hint_number: int)
signal autotype_solution(code_string: String)
signal step_advanced(step_id: int)

const GRID_MIN := 0
const GRID_MAX := 9
const HINT_DELAY_SHOW := 45.0
const HINT_DELAY_AUTOTYPE := 90.0

# Building index map (GridMap mesh library indices)
const BUILDING_INDICES := {
	"house": 7,
	"shop": 8,
	"park": 9,
	"tree": 13,
	"road": 0,
}

var gridmap: GridMap = null
var completed := false
var hint_count := 0
var _idle_timer := 0.0
var _hint_shown := false
var _autotype_fired := false
var _code_has_run := false

var current_step_index := 0
var placed_buildings: Array = []  # Array of {"type": String, "col": int, "row": int}

var mission_title := "Mission 1: Build Your First City!"
var mission_description := "Learn to place buildings on the city grid using code."
var starter_code := ""

# Step definitions — 10-step curriculum
var steps: Array = [
	{
		"id": 1,
		"type": "explain",
		"title": "Meet Your City Grid",
		"mayor_dialogue": "Welcome, Mayor! Your city is built on a grid — like graph paper. Every spot has two numbers: a [b]column[/b] (left-right) and a [b]row[/b] (front-back).",
		"instruction": "Look at the grid. Column 0 is the left edge, Row 0 is the top edge. Column 0, Row 0 is the top-left corner.",
		"show_grid_diagram": true,
		"starter_code": "",
		"hint": "",
		"success_condition": "explain",
		"required_buildings": [],
		"required_count": 0,
		"required_types": 0,
		"available_commands": ["place_building"],
	},
	{
		"id": 2,
		"type": "guided",
		"title": "Your First House",
		"mayor_dialogue": "Let's build! I've written the code for you. Just press [b]Run[/b] to see a house appear at the top-left corner!",
		"instruction": "Press the Run button to execute the code below.",
		"show_grid_diagram": false,
		"starter_code": 'place_building("house", 0, 0)',
		"hint": "Just click the green Run button at the top of the code editor!",
		"success_condition": "code_runs",
		"required_buildings": [],
		"required_count": 0,
		"required_types": 0,
		"available_commands": ["place_building"],
	},
	{
		"id": 3,
		"type": "guided",
		"title": "Move It Right",
		"mayor_dialogue": "Great job! Now let's move the house to the right. Change the [b]column[/b] number to move left and right.",
		"instruction": "Change the code to place a house at column 2, row 0. Replace the first number with 2.",
		"show_grid_diagram": false,
		"starter_code": 'place_building("house", ___, 0)',
		"hint": "Replace the ___ with the number 2. The code should be: place_building(\"house\", 2, 0)",
		"success_condition": "specific_buildings",
		"required_buildings": [{"type": "house", "col": 2, "row": 0}],
		"required_count": 0,
		"required_types": 0,
		"available_commands": ["place_building"],
	},
	{
		"id": 4,
		"type": "guided",
		"title": "Move It Back",
		"mayor_dialogue": "Awesome! The [b]column[/b] moves left-right. Now let's learn that [b]row[/b] moves front-to-back.",
		"instruction": "Place a house at column 0, row 2. Change the second number to move the house further back.",
		"show_grid_diagram": false,
		"starter_code": 'place_building("house", 0, ___)',
		"hint": "Replace the ___ with the number 2. The code should be: place_building(\"house\", 0, 2)",
		"success_condition": "specific_buildings",
		"required_buildings": [{"type": "house", "col": 0, "row": 2}],
		"required_count": 0,
		"required_types": 0,
		"available_commands": ["place_building"],
	},
	{
		"id": 5,
		"type": "do_it",
		"title": "Build Anywhere!",
		"mayor_dialogue": "You're getting the hang of it! Now write the whole command yourself. Place a house anywhere on the grid!",
		"instruction": "Write place_building(\"house\", col, row) with any column and row numbers from 0 to 9.",
		"show_grid_diagram": false,
		"starter_code": "",
		"hint": "Type: place_building(\"house\", 5, 5) — or pick any numbers you like from 0 to 9!",
		"success_condition": "code_runs",
		"required_buildings": [],
		"required_count": 0,
		"required_types": 0,
		"available_commands": ["place_building"],
	},
	{
		"id": 6,
		"type": "guided",
		"title": "Plant a Tree",
		"mayor_dialogue": "Houses aren't the only thing we can build! Let's add some nature. Press Run to plant a [b]tree[/b]!",
		"instruction": "Press Run to place a tree at column 1, row 1.",
		"show_grid_diagram": false,
		"starter_code": 'place_building("tree", 1, 1)',
		"hint": "Just click Run! The code is already written for you.",
		"success_condition": "code_runs",
		"required_buildings": [],
		"required_count": 0,
		"required_types": 0,
		"available_commands": ["place_building"],
	},
	{
		"id": 7,
		"type": "do_it",
		"title": "Your Own Tree",
		"mayor_dialogue": "Now plant a tree somewhere new! Pick a different spot on the grid.",
		"instruction": "Write the code to place a tree at any location you choose.",
		"show_grid_diagram": false,
		"starter_code": "",
		"hint": "Type: place_building(\"tree\", 3, 4) — remember to put \"tree\" in quotes!",
		"success_condition": "code_runs",
		"required_buildings": [],
		"required_count": 0,
		"required_types": 0,
		"available_commands": ["place_building"],
	},
	{
		"id": 8,
		"type": "challenge",
		"title": "Build to Order",
		"mayor_dialogue": "The city council has a plan! They need specific buildings at specific spots. Can you follow the blueprint?",
		"instruction": "Place these 3 buildings:\n- A house at column 1, row 1\n- A tree at column 3, row 1\n- A shop at column 5, row 1",
		"show_grid_diagram": false,
		"starter_code": "",
		"hint": "Write 3 lines of code, one for each building:\nplace_building(\"house\", 1, 1)\nplace_building(\"tree\", 3, 1)\nplace_building(\"shop\", 5, 1)",
		"success_condition": "specific_buildings",
		"required_buildings": [
			{"type": "house", "col": 1, "row": 1},
			{"type": "tree", "col": 3, "row": 1},
			{"type": "shop", "col": 5, "row": 1},
		],
		"required_count": 0,
		"required_types": 0,
		"available_commands": ["place_building"],
	},
	{
		"id": 9,
		"type": "challenge",
		"title": "Design Your Block",
		"mayor_dialogue": "Time to get creative! Build a small neighborhood with at least 5 buildings. Use at least 2 different types!",
		"instruction": "Place at least 5 buildings using at least 2 different building types (house, tree, shop, park, road).",
		"show_grid_diagram": false,
		"starter_code": "",
		"hint": "Try mixing houses and trees! For example:\nplace_building(\"house\", 2, 2)\nplace_building(\"tree\", 3, 2)\nplace_building(\"house\", 4, 2)\nplace_building(\"tree\", 5, 2)\nplace_building(\"shop\", 6, 2)",
		"success_condition": "type_count",
		"required_buildings": [],
		"required_count": 5,
		"required_types": 2,
		"available_commands": ["place_building"],
	},
	{
		"id": 10,
		"type": "mastery",
		"title": "Master Builder",
		"mayor_dialogue": "You're a true city planner now! Build your dream city. Go wild — place at least 6 buildings with 3 or more different types!",
		"instruction": "Free build! Place at least 6 buildings using at least 3 different types. Build the city of your dreams!",
		"show_grid_diagram": false,
		"starter_code": "",
		"hint": "Use house, tree, shop, park, and road. You need at least 6 buildings total and 3 different kinds!",
		"success_condition": "type_count",
		"required_buildings": [],
		"required_count": 6,
		"required_types": 3,
		"available_commands": ["place_building"],
	},
]


func setup(gm: GridMap) -> void:
	gridmap = gm
	current_step_index = 0
	placed_buildings.clear()
	_load_current_step()


func _process(delta: float) -> void:
	if completed:
		return

	var step := get_current_step()
	if step.type == "explain":
		return

	# Track idle time for hint system
	_idle_timer += delta

	if not _hint_shown and _idle_timer >= HINT_DELAY_SHOW:
		_hint_shown = true
		hint_count += 1
		mission_hint.emit(step.hint, 1)

	if not _autotype_fired and _idle_timer >= HINT_DELAY_AUTOTYPE:
		_autotype_fired = true
		var solution := _get_solution_for_step(step)
		if solution != "":
			autotype_solution.emit(solution)


## Returns the current step Dictionary
func get_current_step() -> Dictionary:
	if current_step_index >= 0 and current_step_index < steps.size():
		return steps[current_step_index]
	return {}


## Returns step data by step id (1-based)
func get_step(step_id: int) -> Dictionary:
	for s in steps:
		if s.id == step_id:
			return s
	return {}


## Called when the student presses Run
func on_code_run() -> void:
	_code_has_run = true
	_reset_idle_timer()


## Resets the idle timer (called on user interaction)
func _reset_idle_timer() -> void:
	_idle_timer = 0.0
	_hint_shown = false
	_autotype_fired = false


## Loads the current step state
func _load_current_step() -> void:
	var step := get_current_step()
	if step.is_empty():
		return

	_reset_idle_timer()
	_code_has_run = false
	placed_buildings.clear()

	# Update starter code
	starter_code = step.starter_code

	# Update mission title/description for MissionManager
	mission_title = "Mission 1: " + step.title
	mission_description = step.instruction


## Advances to the next step (called by Next button for explain, or by success check)
func advance_step() -> void:
	if completed:
		return

	var old_step := get_current_step()
	current_step_index += 1

	if current_step_index >= steps.size():
		# Mission complete!
		completed = true
		mission_completed.emit()
		return

	var new_step := get_current_step()

	# Clear city between steps, except steps 9->10 persist
	if old_step.id != 9 or new_step.id != 10:
		clear_city()

	_load_current_step()
	step_advanced.emit(new_step.id)


## Clears all non-grass buildings from the grid
func clear_city() -> void:
	if not gridmap:
		return
	# Clear all cells and refill with grass
	gridmap.clear()
	for x in range(10):
		for z in range(10):
			gridmap.set_cell_item(Vector3i(x, 0, z), 12)  # GRASS_INDEX = 12
	placed_buildings.clear()


## API function called by CodeRunner
func api_place_building(args: Array, line_num: int) -> String:
	if completed:
		return ""

	# Validate argument count
	if args.size() != 3:
		return "Line %d: place_building needs 3 things: a name, column, and row. Example: place_building(\"house\", 5, 5)" % line_num

	var building_name = args[0]
	var col = args[1]
	var row = args[2]

	# Validate building name is a string
	if not building_name is String:
		return "Line %d: The first thing should be a building name in quotes, like \"house\"" % line_num

	# Validate building name exists
	var bname_lower: String = building_name.to_lower()
	if bname_lower not in BUILDING_INDICES:
		var valid_names := ", ".join(BUILDING_INDICES.keys())
		return "Line %d: I don't know how to build a \"%s\". Try one of: %s" % [line_num, building_name, valid_names]

	# Validate col and row are numbers
	if not col is int and not col is float:
		return "Line %d: The column should be a number (0-9), not \"%s\"" % [line_num, str(col)]
	if not row is int and not row is float:
		return "Line %d: The row should be a number (0-9), not \"%s\"" % [line_num, str(row)]

	var ci: int = int(col)
	var ri: int = int(row)

	# Validate bounds
	if ci < GRID_MIN or ci > GRID_MAX:
		return "Line %d: Column %d is off the map! Use a number between %d and %d." % [line_num, ci, GRID_MIN, GRID_MAX]
	if ri < GRID_MIN or ri > GRID_MAX:
		return "Line %d: Row %d is off the map! Use a number between %d and %d." % [line_num, ri, GRID_MIN, GRID_MAX]

	# Place the building
	if not gridmap:
		return "Line %d: Oops, the city grid isn't ready yet. Try again in a moment!" % line_num

	var structure_index: int = BUILDING_INDICES[bname_lower]
	var cell_pos := Vector3i(ci, 0, ri)
	gridmap.set_cell_item(cell_pos, structure_index)

	# Track placement
	placed_buildings.append({"type": bname_lower, "col": ci, "row": ri})

	mission_feedback.emit("Placed a %s at column %d, row %d!" % [bname_lower, ci, ri])

	# Check if step is now complete
	_check_step_success()

	return ""


## API print function
func api_print(msg: String) -> void:
	mission_feedback.emit(msg)


## Checks if the current step's success condition is met
func _check_step_success() -> void:
	var step := get_current_step()
	if step.is_empty():
		return

	var condition: String = step.success_condition

	match condition:
		"explain":
			# Handled by Next button, not code execution
			return

		"code_runs":
			# Any successful code execution passes
			advance_step()

		"specific_buildings":
			# All required buildings must be placed at exact positions
			var required: Array = step.required_buildings
			var all_matched := true
			for req in required:
				var found := false
				for placed in placed_buildings:
					if placed.type == req.type and placed.col == req.col and placed.row == req.row:
						found = true
						break
				if not found:
					all_matched = false
					break
			if all_matched and required.size() > 0:
				advance_step()

		"count":
			# Total buildings placed must meet required_count
			if placed_buildings.size() >= step.required_count:
				advance_step()

		"type_count":
			# Total buildings >= required_count AND distinct types >= required_types
			if placed_buildings.size() >= step.required_count:
				var types := {}
				for b in placed_buildings:
					types[b.type] = true
				if types.size() >= step.required_types:
					advance_step()


## Returns a valid solution string for autotype
func _get_solution_for_step(step: Dictionary) -> String:
	match step.id:
		2: return 'place_building("house", 0, 0)'
		3: return 'place_building("house", 2, 0)'
		4: return 'place_building("house", 0, 2)'
		5: return 'place_building("house", 5, 5)'
		6: return 'place_building("tree", 1, 1)'
		7: return 'place_building("tree", 3, 4)'
		8: return "place_building(\"house\", 1, 1)\nplace_building(\"tree\", 3, 1)\nplace_building(\"shop\", 5, 1)"
		9: return "place_building(\"house\", 1, 1)\nplace_building(\"tree\", 2, 1)\nplace_building(\"shop\", 3, 1)\nplace_building(\"house\", 4, 1)\nplace_building(\"tree\", 5, 1)"
		10: return "place_building(\"house\", 1, 1)\nplace_building(\"tree\", 2, 1)\nplace_building(\"shop\", 3, 1)\nplace_building(\"park\", 4, 1)\nplace_building(\"road\", 5, 1)\nplace_building(\"house\", 6, 1)"
	if step.starter_code != "":
		return step.starter_code
	return ""

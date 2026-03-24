class_name Mission3
extends Node

# Mission 3: Variables — 10-Step Curriculum
# Students learn to use variables to store and reuse values.

signal mission_completed
signal mission_feedback(message: String)
signal mission_hint(hint_text: String, hint_number: int)
signal autotype_solution(code_string: String)
signal step_advanced(step_id: int)

const GRID_MIN := 0
const GRID_MAX := 9

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
var placed_buildings: Array = []

var mission_title := "Mission 3: Variables"
var mission_description := "Learn to use variables to store and reuse values."
var starter_code := ""

var steps: Array = [
	{
		"id": 1,
		"type": "explain",
		"title": "What's a Variable?",
		"mayor_dialogue": "Imagine you're planning where to build the town park. Instead of remembering 'column 4', you could write it down and give it a name. That note with a name is a VARIABLE!",
		"instruction": "A variable stores a value so you can use it by name.\n\nExample:\nvar spot = 4\nplace_building(\"park\", spot, 0)\n\nNow 'spot' means 4. Change spot to 7 and the park moves!",
		"show_grid_diagram": false,
		"starter_code": "",
		"hint": "",
		"success_condition": "explain",
		"required_buildings": [],
		"required_count": 0,
		"required_types": 0,
		"available_commands": ["var", "place_building"],
	},
	{
		"id": 2,
		"type": "guided",
		"title": "Use a Variable",
		"mayor_dialogue": "Here's code that uses a variable called 'col'. Run it and watch where the house appears!",
		"instruction": "Press Run. The variable 'col' holds the value 3 — so the house goes to column 3.",
		"show_grid_diagram": false,
		"starter_code": "var col = 3\nplace_building(\"house\", col, 0)",
		"hint": "Just press Run — the code is correct!",
		"success_condition": "code_runs",
		"required_buildings": [],
		"required_count": 0,
		"required_types": 0,
		"available_commands": ["var", "place_building"],
	},
	{
		"id": 3,
		"type": "guided",
		"title": "Change the Variable",
		"mayor_dialogue": "Now change the value of 'col' to move the house to column 7. You only change ONE number — and the house moves!",
		"instruction": "Change the value of col from 3 to 7.\nRun the code — the house should appear at column 7.",
		"show_grid_diagram": false,
		"starter_code": "var col = 3\nplace_building(\"house\", col, 0)",
		"hint": "Change the first line to: var col = 7",
		"success_condition": "specific_buildings",
		"required_buildings": [
			{"type": "house", "col": 7, "row": 0},
		],
		"required_count": 0,
		"required_types": 0,
		"available_commands": ["var", "place_building"],
	},
	{
		"id": 4,
		"type": "guided",
		"title": "Two Variables",
		"mayor_dialogue": "You can have as many variables as you need! Here we use 'col' and 'row' together to pinpoint any spot on the grid.",
		"instruction": "Run this code. Then change both col and row to different numbers and run again.",
		"show_grid_diagram": false,
		"starter_code": "var col = 2\nvar row = 4\nplace_building(\"park\", col, row)",
		"hint": "Just press Run first to see it work. Then try changing the numbers!",
		"success_condition": "code_runs",
		"required_buildings": [],
		"required_count": 0,
		"required_types": 0,
		"available_commands": ["var", "place_building"],
	},
	{
		"id": 5,
		"type": "do_it",
		"title": "Place It Yourself",
		"mayor_dialogue": "Your turn! Use two variables to place a shop at column 5, row 3.",
		"instruction": "Declare a variable for the column and another for the row.\nUse them to place a shop at column 5, row 3.",
		"show_grid_diagram": false,
		"starter_code": "",
		"hint": "var col = 5\nvar row = 3\nplace_building(\"shop\", col, row)",
		"success_condition": "specific_buildings",
		"required_buildings": [
			{"type": "shop", "col": 5, "row": 3},
		],
		"required_count": 0,
		"required_types": 0,
		"available_commands": ["var", "place_building"],
	},
	{
		"id": 6,
		"type": "guided",
		"title": "Variables in Loops",
		"mayor_dialogue": "Variables and loops are best friends! Watch how we use a variable to control where a whole row of houses starts.",
		"instruction": "Run this code. The variable 'start' controls where the row begins. Try changing start to 2 and run again.",
		"show_grid_diagram": false,
		"starter_code": "var start = 0\nfor i in range(4):\n    place_building(\"house\", start + i, 0)",
		"hint": "Change 'var start = 0' to 'var start = 2' and press Run.",
		"success_condition": "code_runs",
		"required_buildings": [],
		"required_count": 0,
		"required_types": 0,
		"available_commands": ["var", "for", "place_building"],
	},
	{
		"id": 7,
		"type": "do_it",
		"title": "Move the Whole Street",
		"mayor_dialogue": "The city wants the shopping district to start at column 3. Use a variable to set the starting column and build 4 shops.",
		"instruction": "Use a variable called 'start' set to 3.\nLoop to place 4 shops starting at column 3, all on row 5.",
		"show_grid_diagram": false,
		"starter_code": "",
		"hint": "var start = 3\nfor i in range(4):\n    place_building(\"shop\", start + i, 5)",
		"success_condition": "count",
		"required_buildings": [],
		"required_count": 4,
		"required_types": 0,
		"available_commands": ["var", "for", "place_building"],
	},
	{
		"id": 8,
		"type": "challenge",
		"title": "Named Zones",
		"mayor_dialogue": "Great planners name their zones! Use variables called 'house_row' and 'park_row' to build two distinct areas.",
		"instruction": "Declare:\n  var house_row = 1\n  var park_row = 5\n\nThen place:\n- 3 houses on house_row\n- 3 parks on park_row",
		"show_grid_diagram": false,
		"starter_code": "var house_row = 1\nvar park_row = 5",
		"hint": "var house_row = 1\nvar park_row = 5\nfor i in range(3):\n    place_building(\"house\", i, house_row)\nfor i in range(3):\n    place_building(\"park\", i, park_row)",
		"success_condition": "type_count",
		"required_buildings": [],
		"required_count": 6,
		"required_types": 2,
		"available_commands": ["var", "for", "place_building"],
	},
	{
		"id": 9,
		"type": "challenge",
		"title": "Reuse Your Variables",
		"mayor_dialogue": "Here's a real test: use a single variable to place 3 different buildings in a diagonal line — each one one column and one row further than the last.",
		"instruction": "Place 3 buildings diagonally:\n- house at (1, 1)\n- shop at (2, 2)\n- park at (3, 3)\n\nUse a variable and try to avoid repeating numbers.",
		"show_grid_diagram": false,
		"starter_code": "",
		"hint": "var pos = 1\nplace_building(\"house\", pos, pos)\npos = pos + 1\nplace_building(\"shop\", pos, pos)\npos = pos + 1\nplace_building(\"park\", pos, pos)",
		"success_condition": "specific_buildings",
		"required_buildings": [
			{"type": "house", "col": 1, "row": 1},
			{"type": "shop", "col": 2, "row": 2},
			{"type": "park", "col": 3, "row": 3},
		],
		"required_count": 0,
		"required_types": 0,
		"available_commands": ["var", "for", "place_building"],
	},
	{
		"id": 10,
		"type": "mastery",
		"title": "Variable Planner",
		"mayor_dialogue": "You're thinking like a real city planner! Use variables to design and build a neighborhood of your own. At least 6 buildings, 3 types — and use at least 2 named variables.",
		"instruction": "Free build!\n- At least 6 buildings\n- At least 3 different types\n- Use at least 2 variables in your code",
		"show_grid_diagram": false,
		"starter_code": "",
		"hint": "var main_row = 2\nvar side_row = 5\nfor i in range(3):\n    place_building(\"house\", i, main_row)\nfor i in range(2):\n    place_building(\"shop\", i + 4, main_row)\nfor i in range(3):\n    place_building(\"tree\", i, side_row)",
		"success_condition": "type_count",
		"required_buildings": [],
		"required_count": 6,
		"required_types": 3,
		"available_commands": ["var", "for", "repeat", "place_building"],
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
	if step.is_empty() or step.type == "explain":
		return

	_idle_timer += delta

	if not _hint_shown and _idle_timer >= 45.0:
		_hint_shown = true
		hint_count += 1
		mission_hint.emit(step.hint, 1)

	if not _autotype_fired and _idle_timer >= 90.0:
		_autotype_fired = true
		var solution := _get_solution_for_step(step)
		if solution != "":
			autotype_solution.emit(solution)


func get_current_step() -> Dictionary:
	if current_step_index >= 0 and current_step_index < steps.size():
		return steps[current_step_index]
	return {}


func get_step(step_id: int) -> Dictionary:
	for s in steps:
		if s.id == step_id:
			return s
	return {}


func on_code_run() -> void:
	_code_has_run = true
	_reset_idle_timer()


func _reset_idle_timer() -> void:
	_idle_timer = 0.0
	_hint_shown = false
	_autotype_fired = false


func _load_current_step() -> void:
	var step := get_current_step()
	if step.is_empty():
		return

	_reset_idle_timer()
	_code_has_run = false
	placed_buildings.clear()
	starter_code = step.starter_code
	mission_title = "Mission 3: " + step.title
	mission_description = step.instruction


func advance_step() -> void:
	if completed:
		return

	var old_step := get_current_step()
	current_step_index += 1

	if current_step_index >= steps.size():
		completed = true
		mission_completed.emit()
		return

	var new_step := get_current_step()

	_load_current_step()
	step_advanced.emit(new_step.id)

	if old_step.id != 9 or new_step.id != 10:
		await get_tree().create_timer(0.5).timeout
		_clear_buildings()


func _clear_buildings() -> void:
	if not gridmap:
		return
	gridmap.clear()
	for x in range(10):
		for z in range(10):
			gridmap.set_cell_item(Vector3i(x, 0, z), 12)
	placed_buildings.clear()


func api_place_building(args: Array, line_num: int) -> String:
	if completed:
		return ""

	if args.size() != 3:
		return "Line %d: place_building needs 3 things: a name, column, and row." % line_num

	var building_name = args[0]
	var col = args[1]
	var row = args[2]

	if not building_name is String:
		return "Line %d: The first thing should be a building name in quotes, like \"house\"" % line_num

	var bname_lower: String = building_name.to_lower()
	if bname_lower not in BUILDING_INDICES:
		var valid_names := ", ".join(BUILDING_INDICES.keys())
		return "Line %d: I don't know how to build a \"%s\". Try one of: %s" % [line_num, building_name, valid_names]

	if not (col is int or col is float) or not (row is int or row is float):
		return "Line %d: Column and row should be numbers." % line_num

	var ci: int = int(col)
	var ri: int = int(row)

	if ci < GRID_MIN or ci > GRID_MAX or ri < GRID_MIN or ri > GRID_MAX:
		return "Line %d: Position (%d, %d) is off the map! Use numbers between 0 and 9." % [line_num, ci, ri]

	if not gridmap:
		return "Line %d: The city grid isn't ready yet." % line_num

	var structure_index: int = BUILDING_INDICES[bname_lower]
	gridmap.set_cell_item(Vector3i(ci, 0, ri), structure_index)
	placed_buildings.append({"type": bname_lower, "col": ci, "row": ri})

	mission_feedback.emit("Placed a %s at column %d, row %d!" % [bname_lower, ci, ri])

	_check_step_success()
	return ""


func api_print(msg: String) -> void:
	mission_feedback.emit(msg)


func _check_step_success() -> void:
	var step := get_current_step()
	if step.is_empty():
		return

	var condition: String = step.success_condition

	match condition:
		"explain":
			return

		"code_runs":
			_announce_step_complete()

		"specific_buildings":
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
				_announce_step_complete()

		"count":
			if placed_buildings.size() >= step.required_count:
				_announce_step_complete()

		"type_count":
			if placed_buildings.size() >= step.required_count:
				var types := {}
				for b in placed_buildings:
					types[b.type] = true
				if types.size() >= step.required_types:
					_announce_step_complete()


func _announce_step_complete() -> void:
	var step := get_current_step()
	var step_title: String = step.get("title", "Step")
	
	mission_feedback.emit("🎉 " + step_title + " complete! Great job!")
	
	await get_tree().create_timer(0.8).timeout
	advance_step()


func _get_solution_for_step(step: Dictionary) -> String:
	match step.id:
		3: return "var col = 7\nplace_building(\"house\", col, 0)"
		5: return "var col = 5\nvar row = 3\nplace_building(\"shop\", col, row)"
		7: return "var start = 3\nfor i in range(4):\n    place_building(\"shop\", start + i, 5)"
		8: return "var house_row = 1\nvar park_row = 5\nfor i in range(3):\n    place_building(\"house\", i, house_row)\nfor i in range(3):\n    place_building(\"park\", i, park_row)"
		9: return "var pos = 1\nplace_building(\"house\", pos, pos)\npos = pos + 1\nplace_building(\"shop\", pos, pos)\npos = pos + 1\nplace_building(\"park\", pos, pos)"
		10: return "var main_row = 2\nvar side_row = 5\nfor i in range(3):\n    place_building(\"house\", i, main_row)\nfor i in range(2):\n    place_building(\"shop\", i + 4, main_row)\nfor i in range(3):\n    place_building(\"tree\", i, side_row)"
	if step.starter_code != "":
		return step.starter_code
	return ""

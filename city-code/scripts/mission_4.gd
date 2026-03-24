class_name Mission4
extends Node

# Mission 4: Arrays — 10-Step Curriculum
# Students learn to use arrays to store and access lists of values.

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

var mission_title := "Mission 4: Arrays"
var mission_description := "Learn to use arrays to store lists of values."
var starter_code := ""

var steps: Array = [
	{
		"id": 1,
		"type": "explain",
		"title": "What's an Array?",
		"mayor_dialogue": "Imagine a blueprint with a list of buildings to place: house, shop, park, tree. Instead of four separate variables, we put them all in one list — an ARRAY!",
		"instruction": "An array holds multiple values in order:\n\nvar plan = [\"house\", \"shop\", \"park\"]\n\nAccess each item by its position number, starting at 0:\n  plan[0]  → \"house\"\n  plan[1]  → \"shop\"\n  plan[2]  → \"park\"",
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
		"title": "Access Item 0",
		"mayor_dialogue": "Arrays start counting at ZERO. So the first item is index 0. Run this code and see which building appears!",
		"instruction": "Run this code. The array has 3 buildings — this code places the FIRST one (index 0).",
		"show_grid_diagram": false,
		"starter_code": "var plan = [\"house\", \"shop\", \"park\"]\nplace_building(plan[0], 3, 3)",
		"hint": "Just press Run — index 0 is the first item: house.",
		"success_condition": "code_runs",
		"required_buildings": [],
		"required_count": 0,
		"required_types": 0,
		"available_commands": ["var", "place_building"],
	},
	{
		"id": 3,
		"type": "guided",
		"title": "Access by Index",
		"mayor_dialogue": "Now change the index from 0 to 1 to place the second item in the array — the shop!",
		"instruction": "Change plan[0] to plan[1] and run.\nThe shop should appear instead of the house.",
		"show_grid_diagram": false,
		"starter_code": "var plan = [\"house\", \"shop\", \"park\"]\nplace_building(plan[0], 3, 3)",
		"hint": "Change the second line to: place_building(plan[1], 3, 3)",
		"success_condition": "specific_buildings",
		"required_buildings": [
			{"type": "shop", "col": 3, "row": 3},
		],
		"required_count": 0,
		"required_types": 0,
		"available_commands": ["var", "place_building"],
	},
	{
		"id": 4,
		"type": "guided",
		"title": "Place All Three",
		"mayor_dialogue": "Let's place all three buildings from the array — each at a different column.",
		"instruction": "Run this code. It places each item in the array at a different column.",
		"show_grid_diagram": false,
		"starter_code": "var plan = [\"house\", \"shop\", \"park\"]\nplace_building(plan[0], 0, 0)\nplace_building(plan[1], 2, 0)\nplace_building(plan[2], 4, 0)",
		"hint": "Just press Run — the code places all 3 buildings from the array.",
		"success_condition": "code_runs",
		"required_buildings": [],
		"required_count": 0,
		"required_types": 0,
		"available_commands": ["var", "place_building"],
	},
	{
		"id": 5,
		"type": "do_it",
		"title": "Build Your Own Plan",
		"mayor_dialogue": "Create your own array with 3 building types and place them in a row at columns 1, 3, and 5 on row 5.",
		"instruction": "Declare an array called 'plan' with any 3 building types.\nPlace plan[0] at (1, 5), plan[1] at (3, 5), plan[2] at (5, 5).",
		"show_grid_diagram": false,
		"starter_code": "var plan = [",
		"hint": "var plan = [\"house\", \"tree\", \"shop\"]\nplace_building(plan[0], 1, 5)\nplace_building(plan[1], 3, 5)\nplace_building(plan[2], 5, 5)",
		"success_condition": "count",
		"required_buildings": [],
		"required_count": 3,
		"required_types": 0,
		"available_commands": ["var", "place_building"],
	},
	{
		"id": 6,
		"type": "guided",
		"title": "Array + Loop",
		"mayor_dialogue": "Here's where arrays get POWERFUL — combine them with a loop to place every item automatically!",
		"instruction": "Run this code. The loop goes through each index and places every building in the array.",
		"show_grid_diagram": false,
		"starter_code": "var plan = [\"house\", \"shop\", \"park\", \"tree\"]\nfor i in range(4):\n    place_building(plan[i], i * 2, 0)",
		"hint": "Just press Run — the loop places all 4 buildings from the array.",
		"success_condition": "code_runs",
		"required_buildings": [],
		"required_count": 0,
		"required_types": 0,
		"available_commands": ["var", "for", "place_building"],
	},
	{
		"id": 7,
		"type": "do_it",
		"title": "Your Array Street",
		"mayor_dialogue": "Design a street of 5 buildings using an array and a loop. You choose the building types!",
		"instruction": "Create an array called 'street' with 5 building types.\nUse a loop to place them at columns 0-4, all on row 3.",
		"show_grid_diagram": false,
		"starter_code": "",
		"hint": "var street = [\"house\", \"shop\", \"house\", \"tree\", \"park\"]\nfor i in range(5):\n    place_building(street[i], i, 3)",
		"success_condition": "count",
		"required_buildings": [],
		"required_count": 5,
		"required_types": 0,
		"available_commands": ["var", "for", "place_building"],
	},
	{
		"id": 8,
		"type": "challenge",
		"title": "Two-Zone Plan",
		"mayor_dialogue": "The city planner wants TWO streets — a residential zone and a commercial zone. Use two arrays!",
		"instruction": "Create two arrays:\n  var residential = [\"house\", \"house\", \"park\"]\n  var commercial = [\"shop\", \"shop\", \"shop\"]\n\nLoop to place residential on row 1 and commercial on row 5.",
		"show_grid_diagram": false,
		"starter_code": "var residential = [\"house\", \"house\", \"park\"]\nvar commercial = [\"shop\", \"shop\", \"shop\"]",
		"hint": "var residential = [\"house\", \"house\", \"park\"]\nvar commercial = [\"shop\", \"shop\", \"shop\"]\nfor i in range(3):\n    place_building(residential[i], i, 1)\nfor i in range(3):\n    place_building(commercial[i], i, 5)",
		"success_condition": "type_count",
		"required_buildings": [],
		"required_count": 6,
		"required_types": 2,
		"available_commands": ["var", "for", "place_building"],
	},
	{
		"id": 9,
		"type": "challenge",
		"title": "Change the Plan",
		"mayor_dialogue": "The city council changed their minds — they want the 3rd building in the plan to be a park, not a shop. Change just the array and run again!",
		"instruction": "Start with this array:\nvar plan = [\"house\", \"house\", \"shop\", \"house\"]\n\nChange index 2 from shop to park.\nThen loop to place all 4 on row 7.",
		"show_grid_diagram": false,
		"starter_code": "var plan = [\"house\", \"house\", \"shop\", \"house\"]\n# Change index 2 to park, then place them all",
		"hint": "var plan = [\"house\", \"house\", \"park\", \"house\"]\nfor i in range(4):\n    place_building(plan[i], i, 7)",
		"success_condition": "specific_buildings",
		"required_buildings": [
			{"type": "house", "col": 0, "row": 7},
			{"type": "house", "col": 1, "row": 7},
			{"type": "park", "col": 2, "row": 7},
			{"type": "house", "col": 3, "row": 7},
		],
		"required_count": 0,
		"required_types": 0,
		"available_commands": ["var", "for", "place_building"],
	},
	{
		"id": 10,
		"type": "mastery",
		"title": "Master Planner",
		"mayor_dialogue": "You're thinking in arrays now! Design a full city block using at least one array with 5+ items and a loop to place them all. At least 3 different building types.",
		"instruction": "Free build using arrays!\n- Array with at least 5 items\n- Loop to place them\n- At least 3 different building types\n- At least 8 buildings total",
		"show_grid_diagram": false,
		"starter_code": "",
		"hint": "var block = [\"house\", \"shop\", \"house\", \"park\", \"tree\", \"house\", \"shop\", \"tree\"]\nfor i in range(8):\n    place_building(block[i], i, 0)",
		"success_condition": "type_count",
		"required_buildings": [],
		"required_count": 8,
		"required_types": 3,
		"available_commands": ["var", "for", "place_building"],
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
	mission_title = "Mission 4: " + step.title
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
		3: return "var plan = [\"house\", \"shop\", \"park\"]\nplace_building(plan[1], 3, 3)"
		5: return "var plan = [\"house\", \"tree\", \"shop\"]\nplace_building(plan[0], 1, 5)\nplace_building(plan[1], 3, 5)\nplace_building(plan[2], 5, 5)"
		7: return "var street = [\"house\", \"shop\", \"house\", \"tree\", \"park\"]\nfor i in range(5):\n    place_building(street[i], i, 3)"
		8: return "var residential = [\"house\", \"house\", \"park\"]\nvar commercial = [\"shop\", \"shop\", \"shop\"]\nfor i in range(3):\n    place_building(residential[i], i, 1)\nfor i in range(3):\n    place_building(commercial[i], i, 5)"
		9: return "var plan = [\"house\", \"house\", \"park\", \"house\"]\nfor i in range(4):\n    place_building(plan[i], i, 7)"
		10: return "var block = [\"house\", \"shop\", \"house\", \"park\", \"tree\", \"house\", \"shop\", \"tree\"]\nfor i in range(8):\n    place_building(block[i], i, 0)"
	if step.starter_code != "":
		return step.starter_code
	return ""

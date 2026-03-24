class_name Mission7
extends Node

# Mission 7: Conditionals — 10-Step Curriculum
# Students learn to use if/else statements to make decisions.

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

var mission_title := "Mission 7: Conditionals"
var mission_description := "Learn to make decisions with if/else."
var starter_code := ""

var steps: Array = [
	{
		"id": 1,
		"type": "explain",
		"title": "The City Decides",
		"mayor_dialogue": "What if the city could build different things depending on the situation? If the population is high, build a shop. If it's low, build a house. That 'if' is a conditional — and it's how code gets smart!",
		"instruction": "A conditional checks a condition and decides what to do:\n\nif population > 5:\n    place_building(\"shop\", 3, 3)\n\nIf population is greater than 5 → the shop gets placed.\nIf not → nothing happens.",
		"show_grid_diagram": false,
		"starter_code": "",
		"hint": "",
		"success_condition": "explain",
		"required_buildings": [],
		"required_count": 0,
		"required_types": 0,
		"available_commands": ["if", "var", "place_building"],
	},
	{
		"id": 2,
		"type": "guided",
		"title": "Your First If",
		"mayor_dialogue": "Run this code. The variable 'pop' is 8 — bigger than 5 — so the condition is TRUE and the shop appears!",
		"instruction": "Run this code. pop = 8, which IS greater than 5, so the shop is placed.",
		"show_grid_diagram": false,
		"starter_code": "var pop = 8\nif pop > 5:\n    place_building(\"shop\", 3, 3)",
		"hint": "Just press Run — pop is 8, the condition is true, shop appears.",
		"success_condition": "code_runs",
		"required_buildings": [],
		"required_count": 0,
		"required_types": 0,
		"available_commands": ["if", "var", "place_building"],
	},
	{
		"id": 3,
		"type": "guided",
		"title": "Make It False",
		"mayor_dialogue": "Now change pop to 3. The condition becomes FALSE — so nothing gets placed. Run it and see!",
		"instruction": "Change 'var pop = 8' to 'var pop = 3'.\nRun — the shop should NOT appear because 3 is not greater than 5.",
		"show_grid_diagram": false,
		"starter_code": "var pop = 8\nif pop > 5:\n    place_building(\"shop\", 3, 3)",
		"hint": "Change to: var pop = 3\nThe condition 3 > 5 is false, so nothing is placed.",
		"success_condition": "count",
		"required_buildings": [],
		"required_count": 0,
		"required_types": 0,
		"available_commands": ["if", "var", "place_building"],
	},
	{
		"id": 4,
		"type": "guided",
		"title": "If / Else",
		"mayor_dialogue": "What if we want something to happen EITHER WAY? Use 'else' — if the condition is true, do one thing; otherwise, do another!",
		"instruction": "Run this code. pop = 3, so the 'else' branch runs and a house is placed.\nThen change pop to 8 and run again — now the shop appears instead!",
		"show_grid_diagram": false,
		"starter_code": "var pop = 3\nif pop > 5:\n    place_building(\"shop\", 3, 3)\nelse:\n    place_building(\"house\", 3, 3)",
		"hint": "Run first with pop = 3 (house appears). Then change to pop = 8 (shop appears).",
		"success_condition": "code_runs",
		"required_buildings": [],
		"required_count": 0,
		"required_types": 0,
		"available_commands": ["if", "else", "var", "place_building"],
	},
	{
		"id": 5,
		"type": "do_it",
		"title": "Write Your Own If",
		"mayor_dialogue": "The city happiness is low — only 3. If happiness is less than 5, build a park at (4, 4) to cheer people up!",
		"instruction": "Declare: var happiness = 3\nWrite an if statement: if happiness < 5, place a park at (4, 4).",
		"show_grid_diagram": false,
		"starter_code": "",
		"hint": "var happiness = 3\nif happiness < 5:\n    place_building(\"park\", 4, 4)",
		"success_condition": "specific_buildings",
		"required_buildings": [
			{"type": "park", "col": 4, "row": 4},
		],
		"required_count": 0,
		"required_types": 0,
		"available_commands": ["if", "var", "place_building"],
	},
	{
		"id": 6,
		"type": "guided",
		"title": "If Inside a Loop",
		"mayor_dialogue": "Here's where it gets exciting — put an if INSIDE a loop and each building decides its own type based on its position!",
		"instruction": "Run this code. Even columns get houses, odd columns get parks — the if checks whether col is even using the % operator (remainder).",
		"show_grid_diagram": false,
		"starter_code": "for col in range(6):\n    if col % 2 == 0:\n        place_building(\"house\", col, 0)\n    else:\n        place_building(\"park\", col, 0)",
		"hint": "Just press Run — the % 2 check alternates between houses and parks.",
		"success_condition": "code_runs",
		"required_buildings": [],
		"required_count": 0,
		"required_types": 0,
		"available_commands": ["if", "else", "for", "place_building"],
	},
	{
		"id": 7,
		"type": "do_it",
		"title": "Alternating Street",
		"mayor_dialogue": "Design a 6-building street that alternates between shops and trees!",
		"instruction": "Write a loop for 6 columns on row 3.\nIf the column is even → shop.\nIf the column is odd → tree.",
		"show_grid_diagram": false,
		"starter_code": "",
		"hint": "for col in range(6):\n    if col % 2 == 0:\n        place_building(\"shop\", col, 3)\n    else:\n        place_building(\"tree\", col, 3)",
		"success_condition": "type_count",
		"required_buildings": [],
		"required_count": 6,
		"required_types": 2,
		"available_commands": ["if", "else", "for", "place_building"],
	},
	{
		"id": 8,
		"type": "challenge",
		"title": "Zone by Column",
		"mayor_dialogue": "Smart zoning! Columns 0-3 are residential (houses), columns 4-6 are commercial (shops). Use if to enforce the zone rules.",
		"instruction": "Write a loop for 7 columns on row 0.\nIf col < 4 → place a house.\nElse → place a shop.",
		"show_grid_diagram": false,
		"starter_code": "",
		"hint": "for col in range(7):\n    if col < 4:\n        place_building(\"house\", col, 0)\n    else:\n        place_building(\"shop\", col, 0)",
		"success_condition": "type_count",
		"required_buildings": [],
		"required_count": 7,
		"required_types": 2,
		"available_commands": ["if", "else", "for", "place_building"],
	},
	{
		"id": 9,
		"type": "challenge",
		"title": "Border vs Interior",
		"mayor_dialogue": "Fill a 4×4 grid. Border cells get roads, interior cells get parks.",
		"instruction": "Nested loop: 4 rows × 4 columns.\nIf row==0 or row==3 or col==0 or col==3 → place a road.\nElse → place a park.",
		"show_grid_diagram": false,
		"starter_code": "",
		"hint": "for row in range(4):\n    for col in range(4):\n        if row == 0 or row == 3 or col == 0 or col == 3:\n            place_building(\"road\", col, row)\n        else:\n            place_building(\"park\", col, row)",
		"success_condition": "type_count",
		"required_buildings": [],
		"required_count": 16,
		"required_types": 2,
		"available_commands": ["if", "else", "for", "place_building"],
	},
	{
		"id": 10,
		"type": "mastery",
		"title": "Smart City",
		"mayor_dialogue": "Build a SMART city — one where the code decides what to build based on conditions. Use at least one if/else, one loop, and place at least 10 buildings with at least 3 types.",
		"instruction": "Free build using conditionals!\n- At least one if or if/else\n- At least one loop\n- At least 10 buildings\n- At least 3 different building types",
		"show_grid_diagram": false,
		"starter_code": "",
		"hint": "var density = 6\nfor row in range(3):\n    for col in range(4):\n        if density > 5:\n            place_building(\"shop\", col, row)\n        else:\n            place_building(\"house\", col, row)\nfor i in range(4):\n    place_building(\"tree\", i, 4)",
		"success_condition": "type_count",
		"required_buildings": [],
		"required_count": 10,
		"required_types": 3,
		"available_commands": ["if", "else", "for", "var", "place_building"],
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
	mission_title = "Mission 7: " + step.title
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
		3: return "var pop = 3\nif pop > 5:\n    place_building(\"shop\", 3, 3)"
		5: return "var happiness = 3\nif happiness < 5:\n    place_building(\"park\", 4, 4)"
		7: return "for col in range(6):\n    if col % 2 == 0:\n        place_building(\"shop\", col, 3)\n    else:\n        place_building(\"tree\", col, 3)"
		8: return "for col in range(7):\n    if col < 4:\n        place_building(\"house\", col, 0)\n    else:\n        place_building(\"shop\", col, 0)"
		9: return "for row in range(4):\n    for col in range(4):\n        if row == 0 or row == 3 or col == 0 or col == 3:\n            place_building(\"road\", col, row)\n        else:\n            place_building(\"park\", col, row)"
		10: return "var density = 6\nfor row in range(3):\n    for col in range(4):\n        if density > 5:\n            place_building(\"shop\", col, row)\n        else:\n            place_building(\"house\", col, row)\nfor i in range(4):\n    place_building(\"tree\", i, 4)"
	if step.starter_code != "":
		return step.starter_code
	return ""

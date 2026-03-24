class_name Mission5
extends Node

# Mission 5: Nested For Loops — 10-Step Curriculum
# Students learn to use nested loops to fill 2D grids.

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

var mission_title := "Mission 5: Nested Loops"
var mission_description := "Learn to use nested loops to fill 2D grids."
var starter_code := ""

var steps: Array = [
	{
		"id": 1,
		"type": "explain",
		"title": "One Loop = One Row",
		"mayor_dialogue": "You already know a loop fills a row. But a city block is rows AND columns — a grid. To fill a grid, we need a loop inside a loop!",
		"instruction": "One loop fills a line:\nfor col in range(4):\n    place_building(\"house\", col, 0)\n\nBut what if we want 4 rows of 4 houses? We need to run that loop 4 times — which means another loop AROUND it.",
		"show_grid_diagram": true,
		"starter_code": "",
		"hint": "",
		"success_condition": "explain",
		"required_buildings": [],
		"required_count": 0,
		"required_types": 0,
		"available_commands": ["for", "place_building"],
	},
	{
		"id": 2,
		"type": "guided",
		"title": "A Loop Inside a Loop",
		"mayor_dialogue": "Watch carefully — the outer loop moves through rows. For each row, the inner loop fills all 4 columns. Run it!",
		"instruction": "Run this code. Count the buildings — it should place 4 × 3 = 12 houses.\n\nNotice the two different variable names: 'row' and 'col'.",
		"show_grid_diagram": false,
		"starter_code": "for row in range(3):\n    for col in range(4):\n        place_building(\"house\", col, row)",
		"hint": "Just press Run — the nested loop fills 3 rows × 4 columns.",
		"success_condition": "code_runs",
		"required_buildings": [],
		"required_count": 0,
		"required_types": 0,
		"available_commands": ["for", "place_building"],
	},
	{
		"id": 3,
		"type": "guided",
		"title": "Change the Grid Size",
		"mayor_dialogue": "Change the range numbers to make a 5×2 grid — 5 columns, 2 rows.",
		"instruction": "Change the outer range to 2 (rows) and inner range to 5 (columns).\nRun — you should get 10 houses in a 5×2 grid.",
		"show_grid_diagram": false,
		"starter_code": "for row in range(3):\n    for col in range(4):\n        place_building(\"house\", col, row)",
		"hint": "for row in range(2):\n    for col in range(5):\n        place_building(\"house\", col, row)",
		"success_condition": "count",
		"required_buildings": [],
		"required_count": 10,
		"required_types": 0,
		"available_commands": ["for", "place_building"],
	},
	{
		"id": 4,
		"type": "explain",
		"title": "⚠️ The Variable Name Warning",
		"mayor_dialogue": "Here's a trap that catches everyone! If you use the SAME variable name for both loops, the inner loop takes over and your outer loop breaks.",
		"instruction": "WRONG — both loops use 'i':\nfor i in range(3):\n    for i in range(4):\n        place_building(\"house\", i, i)\n\nThis gives you 4 buildings instead of 12.\n\nCORRECT — use different names:\nfor row in range(3):\n    for col in range(4):\n        place_building(\"house\", col, row)\n\nAlways use different names!",
		"show_grid_diagram": false,
		"starter_code": "",
		"hint": "",
		"success_condition": "explain",
		"required_buildings": [],
		"required_count": 0,
		"required_types": 0,
		"available_commands": ["for", "place_building"],
	},
	{
		"id": 5,
		"type": "do_it",
		"title": "Fill a 4×4 Block",
		"mayor_dialogue": "Build a perfect 4×4 block of houses. That's 16 buildings — using a nested loop with just 3 lines of code!",
		"instruction": "Write a nested loop:\n- Outer loop: 4 rows\n- Inner loop: 4 columns\n- Place a house at (col, row) each time\n\nUse different variable names!",
		"show_grid_diagram": false,
		"starter_code": "",
		"hint": "for row in range(4):\n    for col in range(4):\n        place_building(\"house\", col, row)",
		"success_condition": "count",
		"required_buildings": [],
		"required_count": 16,
		"required_types": 0,
		"available_commands": ["for", "place_building"],
	},
	{
		"id": 6,
		"type": "guided",
		"title": "Spacing the Grid",
		"mayor_dialogue": "Buildings right next to each other look cramped. Multiply the col and row by 2 to add spacing between each building!",
		"instruction": "Run this code. Notice the buildings are spaced out — col * 2 and row * 2 create gaps between them.",
		"show_grid_diagram": false,
		"starter_code": "for row in range(3):\n    for col in range(3):\n        place_building(\"house\", col * 2, row * 2)",
		"hint": "Just press Run — the spacing uses multiplication.",
		"success_condition": "code_runs",
		"required_buildings": [],
		"required_count": 0,
		"required_types": 0,
		"available_commands": ["for", "place_building"],
	},
	{
		"id": 7,
		"type": "do_it",
		"title": "Spaced Park Grid",
		"mayor_dialogue": "Build a 3×3 grid of parks with one space between each. That means col×2 and row×2.",
		"instruction": "Write a nested loop:\n- 3 rows, 3 columns\n- Place parks\n- Use col * 2 and row * 2 for spacing",
		"show_grid_diagram": false,
		"starter_code": "",
		"hint": "for row in range(3):\n    for col in range(3):\n        place_building(\"park\", col * 2, row * 2)",
		"success_condition": "count",
		"required_buildings": [],
		"required_count": 9,
		"required_types": 0,
		"available_commands": ["for", "place_building"],
	},
	{
		"id": 8,
		"type": "challenge",
		"title": "Mixed Grid",
		"mayor_dialogue": "Advanced challenge! Fill a 4×4 grid but make the BORDER houses and the INTERIOR parks.",
		"instruction": "Fill a 4×4 grid. The outer edges are houses, the inner 2×2 is parks.\n\nTip: the inner cells are row 1-2, col 1-2.\nAll others are border cells.",
		"show_grid_diagram": false,
		"starter_code": "",
		"hint": "for row in range(4):\n    for col in range(4):\n        if row == 0 or row == 3 or col == 0 or col == 3:\n            place_building(\"house\", col, row)\n        else:\n            place_building(\"park\", col, row)",
		"success_condition": "type_count",
		"required_buildings": [],
		"required_count": 16,
		"required_types": 2,
		"available_commands": ["for", "if", "place_building"],
	},
	{
		"id": 9,
		"type": "challenge",
		"title": "Offset Grid",
		"mayor_dialogue": "The city expansion zone starts at column 3, row 3 — not at 0,0. Use a nested loop to fill a 3×3 block starting at that offset.",
		"instruction": "Build a 3×3 block of shops starting at column 3, row 3 (9 buildings total).\n\nHint: add 3 to both col and row.",
		"show_grid_diagram": false,
		"starter_code": "",
		"hint": "for row in range(3):\n    for col in range(3):\n        place_building(\"shop\", col + 3, row + 3)",
		"success_condition": "count",
		"required_buildings": [],
		"required_count": 9,
		"required_types": 0,
		"available_commands": ["for", "place_building"],
	},
	{
		"id": 10,
		"type": "mastery",
		"title": "City Grid Master",
		"mayor_dialogue": "Final challenge! Design a full city district. Use at least one nested loop, at least 12 buildings, at least 3 different types. Make it look like a real neighborhood.",
		"instruction": "Free build using nested loops!\n- At least one nested loop\n- At least 12 buildings\n- At least 3 different building types",
		"show_grid_diagram": false,
		"starter_code": "",
		"hint": "for row in range(3):\n    for col in range(4):\n        place_building(\"house\", col, row)\nfor col in range(4):\n    place_building(\"shop\", col, 4)\nfor col in range(4):\n    place_building(\"tree\", col, 5)",
		"success_condition": "type_count",
		"required_buildings": [],
		"required_count": 12,
		"required_types": 3,
		"available_commands": ["for", "place_building"],
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
	mission_title = "Mission 5: " + step.title
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
		3: return "for row in range(2):\n    for col in range(5):\n        place_building(\"house\", col, row)"
		5: return "for row in range(4):\n    for col in range(4):\n        place_building(\"house\", col, row)"
		7: return "for row in range(3):\n    for col in range(3):\n        place_building(\"park\", col * 2, row * 2)"
		8: return "for row in range(4):\n    for col in range(4):\n        if row == 0 or row == 3 or col == 0 or col == 3:\n            place_building(\"house\", col, row)\n        else:\n            place_building(\"park\", col, row)"
		9: return "for row in range(3):\n    for col in range(3):\n        place_building(\"shop\", col + 3, row + 3)"
		10: return "for row in range(3):\n    for col in range(4):\n        place_building(\"house\", col, row)\nfor col in range(4):\n    place_building(\"shop\", col, 4)\nfor col in range(4):\n    place_building(\"tree\", col, 5)"
	if step.starter_code != "":
		return step.starter_code
	return ""

class_name Mission13
extends Node

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
var _city_score := 0

var mission_title := "Mission 13: The Happiness Engine"
var mission_description := "Build data-driven systems where code makes decisions."
var starter_code := ""

var steps: Array = [
	{
		"id": 1,
		"type": "explain",
		"title": "The City's Brain",
		"mayor_dialogue": "Mayor, citizens don't just need buildings. They need the RIGHT buildings in the RIGHT places. A shop next to a park raises happiness. Your city has rules. Code those rules. Then let the data tell you what to build next. That is a system.",
		"instruction": "A data-driven system uses SCORES to make decisions:\n\nif park_check():\n    place_building(\"park\", x, y)\n    city_score += 5",
		"show_grid_diagram": false,
		"starter_code": "",
		"hint": "",
		"success_condition": "explain",
		"required_buildings": [],
		"required_count": 0,
		"required_types": 0,
		"available_commands": ["function", "var", "if", "elif", "place_building"],
	},
	{
		"id": 2,
		"type": "do_it",
		"title": "The Scoring System",
		"mayor_dialogue": "Run the starter code. The scoring function places buildings and updates the city score!",
		"instruction": "Run the code. Watch the score change as buildings are placed.",
		"show_grid_diagram": false,
		"starter_code": "var city_score = 0\n\nfunction place_and_score(type, x, y):\n    place_building(type, x, y)\n    if type == \"park\":\n        city_score += 5\n    elif type == \"road\":\n        city_score -= 2\n\nprint(\"Starting score: \" + str(city_score))\nplace_and_score(\"park\", 2, 2)\nprint(\"After park: \" + str(city_score))",
		"hint": "Press Run to see the scoring in action.",
		"success_condition": "code_runs",
		"required_buildings": [],
		"required_count": 0,
		"required_types": 0,
		"available_commands": ["function", "var", "if", "elif", "place_building", "print"],
	},
	{
		"id": 3,
		"type": "do_it",
		"title": "Build a Neighbourhood",
		"mayor_dialogue": "Place 3 houses, 2 parks, and 2 roads using place_and_score. Print the final score!",
		"instruction": "Build a neighbourhood with different building types. Watch the score!",
		"show_grid_diagram": false,
		"starter_code": "var city_score = 0\n\nfunction place_and_score(type, x, y):\n    place_building(type, x, y)\n    if type == \"park\":\n        city_score += 5\n    elif type == \"road\":\n        city_score -= 2\n    elif type == \"house\":\n        city_score += 1",
		"hint": "Call place_and_score 7 times with different buildings.",
		"success_condition": "count",
		"required_buildings": [],
		"required_count": 7,
		"required_types": 0,
		"available_commands": ["function", "var", "if", "elif", "place_building", "print"],
	},
	{
		"id": 4,
		"type": "do_it",
		title": "The Optimiser",
		"mayor_dialogue": "Write function optimise_block(): that tries placing a park, checks if score increases, then tries a shop. Keep whichever scored higher!",
		"instruction": "Create optimise_block(x, y) that:\n1. Saves score before\n2. Tries park\n3. If worse, undo and try shop",
		"show_grid_diagram": false,
		"starter_code": "var city_score = 0\n\nfunction place_and_score(type, x, y):\n    place_building(type, x, y)\n    if type == \"park\":\n        city_score += 5\n    elif type == \"shop\":\n        city_score += 3\n    elif type == \"road\":\n        city_score -= 2",
		"hint": "Save score before trying park, compare after.",
		"success_condition": "code_runs",
		"required_buildings": [],
		"required_count": 0,
		"required_types": 0,
		"available_commands": ["function", "var", "if", "elif", "place_building"],
	},
	{
		"id": 5,
		"type": "do_it",
		"title": "The Happiness Report",
		"mayor_dialogue": "Write function happiness_report(): that prints total score, number of buildings, and a rating!",
		"instruction": "Create:\nfunction happiness_report(total):\n    print(\"Score: \" + str(city_score))\n    print(\"Buildings: \" + str(total))\n    if city_score > 10:\n        print(\"Status: Thriving\")",
		"show_grid_diagram": false,
		"starter_code": "var city_score = 0\n\nfunction place_and_score(type, x, y):\n    place_building(type, x, y)\n    if type == \"park\":\n        city_score += 5",
		"hint": "Add if/elif for rating thresholds.",
		"success_condition": "code_runs",
		"required_buildings": [],
		"required_count": 0,
		"required_types": 0,
		"available_commands": ["function", "var", "if", "elif", "place_building", "print"],
	},
	{
		"id": 6,
		"type": "challenge",
		"title": "The Full Engine",
		"mayor_dialogue": "Build a 4x4 district driven by the scoring system. For each cell, try park first — if score improves, keep it. Otherwise try shop.",
		"instruction": "Create nested loops (4x4). Use the optimiser for each cell. Roads only on row 3. Run happiness report at the end.",
		"show_grid_diagram": false,
		"starter_code": "var city_score = 0\n\nfunction place_and_score(type, x, y):\n    place_building(type, x, y)\n    if type == \"park\":\n        city_score += 5\n    elif type == \"shop\":\n        city_score += 3\n    elif type == \"road\":\n        city_score -= 2",
		"hint": "Use for row in range(4): for col in range(4):",
		"success_condition": "count",
		"required_buildings": [],
		"required_count": 16,
		"required_types": 0,
		"available_commands": ["function", "var", "if", "elif", "for", "place_building", "print"],
	},
	{
		"id": 7,
		"type": "guided",
		"title": "Feedback Loops",
		"mayor_dialogue": "The key insight: output becomes input. Your score affects which buildings get placed, which affects the score again!",
		"instruction": "This is a FEEDBACK LOOP — the output of one decision becomes input for the next.",
		"show_grid_diagram": false,
		"starter_code": "var score = 0\nscore = score + 5\nprint(score)\nscore = score - 2\nprint(score)",
		"hint": "Each decision affects the next decision.",
		"success_condition": "code_runs",
		"required_buildings": [],
		"required_count": 0,
		"required_types": 0,
		"available_commands": ["function", "var", "if", "elif", "place_building", "print"],
	},
	{
		"id": 8,
		"type": "do_it",
		"title": "Decision Boundaries",
		"mayor_dialogue": "Set thresholds: score > 20 = Thriving, > 10 = Growing, else = Struggling. Watch your city cross thresholds!",
		"instruction": "Add elif branches to happiness_report for different thresholds.",
		"show_grid_diagram": false,
		"starter_code": "var city_score = 15\n\nfunction happiness_report():\n    print(\"Score: \" + str(city_score))\n    if city_score > 20:\n        print(\"Status: Thriving\")\n    else:\n        print(\"Status: Growing\")",
		"hint": "Add: elif city_score > 10: for the middle threshold.",
		"success_condition": "code_runs",
		"required_buildings": [],
		"required_count": 0,
		"required_types": 0,
		"available_commands": ["function", "var", "if", "elif", "print"],
	},
	{
		"id": 9,
		"type": "challenge",
		"title": "Optimised District",
		"mayor_dialogue": "Build a 3x3 optimised district where every placement is evaluated against the scoring system!",
		"instruction": "Create an optimiser that evaluates park vs shop for each cell. Track total buildings placed.",
		"show_grid_diagram": false,
		"starter_code": "var city_score = 0\n\nfunction place_and_score(type, x, y):\n    place_building(type, x, y)\n    if type == \"park\":\n        city_score += 5\n    elif type == \"shop\":\n        city_score += 3",
		"hint": "Save score before, try park, compare.",
		"success_condition": "count",
		"required_buildings": [],
		"required_count": 9,
		"required_types": 0,
		"available_commands": ["function", "var", "if", "elif", "for", "place_building", "print"],
	},
	{
		"id": 10,
		"type": "mastery",
		"title": "Happiness Master",
		"mayor_dialogue": "You've mastered data-driven systems! Build a complete city where every decision flows from the happiness score.",
		"instruction": "Create 5x5 district. Scoring: park +5, shop +3, house +2, road -2. Use optimiser for non-road cells. Print final score and rating.",
		"show_grid_diagram": false,
		"starter_code": "var city_score = 0\n\nfunction place_and_score(type, x, y):\n    place_building(type, x, y)",
		"hint": "Row 4 is roads, rows 0-3 use the optimiser.",
		"success_condition": "count",
		"required_buildings": [],
		"required_count": 25,
		"required_types": 0,
		"available_commands": ["function", "var", "if", "elif", "for", "place_building", "print"],
	},
]


func setup(gm: GridMap) -> void:
	gridmap = gm
	_city_score = 0


func _process(delta: float) -> void:
	if _autotype_fired or _code_has_run:
		return
	
	_idle_timer += delta
	if _idle_timer > 90.0:
		_autotype_fired = true
		_autotype_solution()


func on_code_run() -> void:
	_code_has_run = true
	placed_buildings.clear()
	_city_score = 0


func _check_success() -> bool:
	var step = steps[current_step_index]
	var success_type = step.success_condition
	
	match success_type:
		"explain":
			return true
		"code_runs":
			return true
		"count":
			return _check_count(step)
	
	return false


func _check_count(step: Dictionary) -> bool:
	var required = step.get("required_count", 0) as int
	if required == 0:
		return false
	
	var children = get_tree().get_nodes_in_group("placed_building")
	return children.size() >= required


func _announce_step_complete() -> void:
	mission_feedback.emit("Step %d complete!" % (current_step_index + 1))
	await get_tree().create_timer(0.8).timeout
	advance_step()


func advance_step() -> void:
	if current_step_index < steps.size() - 1:
		current_step_index += 1
		step_advanced.emit(current_step_index)
		placed_buildings.clear()
		await get_tree().create_timer(0.5).timeout
		if gridmap:
			gridmap.clear()
			for x in range(10):
				for z in range(10):
					if gridmap.get_cell_item(Vector3i(x, 0, z)) == -1:
						gridmap.set_cell_item(Vector3i(x, 0, z), 12)
	else:
		complete_mission()


func complete_mission() -> void:
	if not completed:
		completed = true
		mission_completed.emit()


func api_place_building(args: Array, line_num: int) -> String:
	if args.size() < 3:
		return "Line %d: place_building needs type, x, and y" % line_num
	
	var type_name = str(args[0])
	var x = int(args[1])
	var z = int(args[2])
	
	if not BUILDING_INDICES.has(type_name):
		return "Line %d: Unknown building type '%s'" % [line_num, type_name]
	
	if gridmap:
		gridmap.set_cell_item(Vector3i(x, 0, z), BUILDING_INDICES[type_name])
	
	_check_and_advance()
	return ""


func _check_and_advance() -> void:
	await get_tree().create_timer(0.2).timeout
	if _check_success():
		_announce_step_complete()


func api_print(msg: String) -> void:
	mission_feedback.emit(str(msg))

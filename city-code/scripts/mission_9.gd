class_name Mission9
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

var mission_title := "Mission 9: The Function Factory"
var mission_description := "Learn to write reusable functions with parameters."
var starter_code := ""

var steps: Array = [
	{
		"id": 1,
		"type": "explain",
		"title": "The Blueprint Problem",
		"mayor_dialogue": "Mayor, your builders are doing the same job over and over. That's not a city — that's chaos. A function is a blueprint. Write it once, use it everywhere!",
		"instruction": "A function is a reusable block of code:\n\nfunction build_row(type, row):\n    for i in range(5):\n        place_building(type, i, row)",
		"show_grid_diagram": false,
		"starter_code": "",
		"hint": "",
		"success_condition": "explain",
		"required_buildings": [],
		"required_count": 0,
		"required_types": 0,
		"available_commands": ["function", "var", "for", "place_building"],
	},
	{
		"id": 2,
		"type": "do_it",
		"title": "Spot the Repetition",
		"mayor_dialogue": "Run the starter code. Three houses appear. Now imagine placing 50 houses. Functions solve this!",
		"instruction": "Run the code. Three houses appear at row 0. This works, but what if you need 20 rows?",
		"show_grid_diagram": false,
		"starter_code": "place_building(\"house\", 0, 0)\nplace_building(\"house\", 1, 0)\nplace_building(\"house\", 2, 0)\nplace_building(\"house\", 3, 0)\nplace_building(\"house\", 4, 0)",
		"hint": "Press Run to see the repetitive approach.",
		"success_condition": "count",
		"required_buildings": [],
		"required_count": 5,
		"required_types": 0,
		"available_commands": ["function", "var", "for", "place_building"],
	},
	{
		"id": 3,
		"type": "do_it",
		"title": "Write Your First Function",
		"mayor_dialogue": "Define: function build_row(type, row): then loop through place_building. Call it: build_row(\"house\", 0)",
		"instruction": "Define function build_row(type, row): with a loop inside. Call it with: build_row(\"house\", 0)",
		"show_grid_diagram": false,
		"starter_code": "function build_row(type, row):\n    for i in range(5):\n        place_building(type, i, row)\n\nbuild_row(\"house\", 0)",
		"hint": "Use parameters like variables inside the function.",
		"success_condition": "count",
		"required_buildings": [],
		"required_count": 5,
		"required_types": 0,
		"available_commands": ["function", "var", "for", "place_building"],
	},
	{
		"id": 4,
		"type": "do_it",
		"title": "Call It Again",
		"mayor_dialogue": "Call build_row(\"shop\", 2) on the next line. One function, two different rows!",
		"instruction": "After build_row(\"house\", 0), add:\nbuild_row(\"shop\", 2)\n\nThe same function creates a row of shops!",
		"show_grid_diagram": false,
		"starter_code": "function build_row(type, row):\n    for i in range(5):\n        place_building(type, i, row)\n\nbuild_row(\"house\", 0)",
		"hint": "Add: build_row(\"shop\", 2) after the first call.",
		"success_condition": "count",
		"required_buildings": [],
		"required_count": 10,
		"required_types": 0,
		"available_commands": ["function", "var", "for", "place_building"],
	},
	{
		"id": 5,
		"type": "challenge",
		"title": "Add a Return Value",
		"mayor_dialogue": "Write func count_row(row): that returns the number 5. Functions can send data back with return!",
		"instruction": "Add: function count_row(row):\n    return 5\n\nThen print the result: print(count_row(0))",
		"show_grid_diagram": false,
		"starter_code": "function build_row(type, row):\n    for i in range(5):\n        place_building(type, i, row)\n\nbuild_row(\"house\", 0)\nbuild_row(\"shop\", 2)",
		"hint": "Use: return 5 at the end of count_row function.",
		"success_condition": "code_runs",
		"required_buildings": [],
		"required_count": 10,
		"required_types": 0,
		"available_commands": ["function", "var", "for", "place_building", "return"],
	},
	{
		"id": 6,
		"type": "challenge",
		"title": "The Full District",
		"mayor_dialogue": "Use build_row to place: houses row 0, parks row 1, shops row 2, trees row 4. Print a report!",
		"instruction": "Call build_row four times with different types and rows. Print a summary report.",
		"show_grid_diagram": false,
		"starter_code": "function build_row(type, row):\n    for i in range(5):\n        place_building(type, i, row)\n\nbuild_row(\"house\", 0)",
		"hint": "Add: build_row(\"park\", 1), build_row(\"shop\", 2), build_row(\"tree\", 4)",
		"success_condition": "count",
		"required_buildings": [],
		"required_count": 20,
		"required_types": 0,
		"available_commands": ["function", "var", "for", "place_building", "return", "print"],
	},
	{
		"id": 7,
		"type": "guided",
		"title": "Parameters vs Arguments",
		"mayor_dialogue": "The 'type' and 'row' in the function definition are PARAMETERS. The values you pass when calling are ARGUMENTS.",
		"instruction": "When you call build_row(\"house\", 0):\n- 'house' is the argument for 'type'\n- 0 is the argument for 'row'",
		"show_grid_diagram": false,
		"starter_code": "function greet(name):\n    print(\"Hello, \" + name + \"!\")\n\ngreet(\"Mayor\")\ngreet(\"Builder\")",
		"hint": "Run to see the function work with different arguments.",
		"success_condition": "code_runs",
		"required_buildings": [],
		"required_count": 0,
		"required_types": 0,
		"available_commands": ["function", "var", "for", "place_building", "print"],
	},
	{
		"id": 8,
		"type": "do_it",
		"title": "Function Composition",
		"mayor_dialogue": "One function can CALL ANOTHER. build_district() calls build_row() — that's composition!",
		"instruction": "Add function build_district():\n    build_row(\"house\", 0)\n    build_row(\"park\", 1)\n\nThen call: build_district()",
		"show_grid_diagram": false,
		"starter_code": "function build_row(type, row):\n    for i in range(4):\n        place_building(type, i, row)\n\nfunction build_district():\n    build_row(\"house\", 0)\n\nbuild_row(\"house\", 0)",
		"hint": "Add build_row(\"park\", 1) inside build_district.",
		"success_condition": "count",
		"required_buildings": [],
		"required_count": 8,
		"required_types": 0,
		"available_commands": ["function", "var", "for", "place_building"],
	},
	{
		"id": 9,
		"type": "challenge",
		"title": "Build the City Plan",
		"mayor_dialogue": "Create 3 functions: build_houses(), build_shops(), city_plan(). City_plan calls the other two!",
		"instruction": "build_houses() places 3 houses at row 0.\nbuild_shops() places 3 shops at row 2.\ncity_plan() calls both.\nCall city_plan()!",
		"show_grid_diagram": false,
		"starter_code": "function build_houses():\n    for i in range(3):\n        place_building(\"house\", i, 0)\n\nfunction build_shops():\n    for i in range(3):\n        place_building(\"shop\", i, 2)",
		"hint": "Add city_plan() that calls build_houses() and build_shops().",
		"success_condition": "count",
		"required_buildings": [],
		"required_count": 6,
		"required_types": 0,
		"available_commands": ["function", "var", "for", "place_building"],
	},
	{
		"id": 10,
		"type": "mastery",
		"title": "The Reusable City",
		"mayor_dialogue": "You've mastered functions! Build a complete city system where small functions combine into big results.",
		"instruction": "Create: build_zone(type, row, count), report_census(count), city_builder(). City_builder calls build_zone twice with different types and report_census at the end.",
		"show_grid_diagram": false,
		"starter_code": "function build_zone(type, row, count):\n    for i in range(count):\n        place_building(type, i, row)",
		"hint": "Call build_zone twice, then call report_census at the end.",
		"success_condition": "count",
		"required_buildings": [],
		"required_count": 8,
		"required_types": 0,
		"available_commands": ["function", "var", "for", "place_building", "print"],
	},
]


func setup(gm: GridMap) -> void:
	gridmap = gm


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


func _autotype_solution() -> void:
	var step = steps[current_step_index]
	if step.has("auto_type"):
		autotype_solution.emit(step.auto_type)

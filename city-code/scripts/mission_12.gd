class_name Mission12
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

var mission_title := "Mission 12: The Event Planner"
var mission_description := "Compose programs with functions calling functions."
var starter_code := ""

var steps: Array = [
	{
		"id": 1,
		"type": "explain",
		"title": "The Giant Function Problem",
		"mayor_dialogue": "Mayor, a city is not one thing running — it is many things running together, each calling on the other. You do not manage each one. You manage the connections. That is architecture.",
		"instruction": "A city is many systems working together:\n\nbuild_everything() → calls build_residential()\n                    → calls build_commercial()\n                    → calls build_roads()",
		"show_grid_diagram": false,
		"starter_code": "",
		"hint": "",
		"success_condition": "explain",
		"required_buildings": [],
		"required_count": 0,
		"required_types": 0,
		"available_commands": ["function", "for", "place_building"],
	},
	{
		"id": 2,
		"type": "do_it",
		"title": "The Giant Block",
		"mayor_dialogue": "Run the starter code. It works — but build_everything does too much. If the park is wrong, you have to search through everything!",
		"instruction": "Run the code. It builds the district but all in one function.",
		"show_grid_diagram": false,
		"starter_code": "function build_everything():\n    place_building(\"house\", 0, 0)\n    place_building(\"house\", 1, 0)\n    place_building(\"shop\", 0, 1)\n    place_building(\"shop\", 1, 1)\n    place_building(\"park\", 0, 2)\n    place_building(\"park\", 1, 2)\n    place_building(\"road\", 0, 3)\n    place_building(\"road\", 1, 3)\n\nbuild_everything()",
		"hint": "Press Run to see the monolithic approach.",
		"success_condition": "count",
		"required_buildings": [],
		"required_count": 8,
		"required_types": 0,
		"available_commands": ["function", "for", "place_building"],
	},
	{
		"id": 3,
		"type": "do_it",
		"title": "Extract build_residential",
		"mayor_dialogue": "Create function build_residential(): that places the houses. Create build_commercial(): that places the shops.",
		"instruction": "Create:\nfunction build_residential():\n    place_building(\"house\", 0, 0)\n    place_building(\"house\", 1, 0)\n\nfunction build_commercial():\n    place_building(\"shop\", 0, 1)\n    place_building(\"shop\", 1, 1)",
		"show_grid_diagram": false,
		"starter_code": "function build_everything():\n    place_building(\"house\", 0, 0)\n    place_building(\"house\", 1, 0)\n    place_building(\"shop\", 0, 1)\n    place_building(\"shop\", 1, 1)\n\nbuild_everything()",
		"hint": "Extract the house lines into build_residential, shop lines into build_commercial.",
		"success_condition": "count",
		"required_buildings": [],
		"required_count": 4,
		"required_types": 0,
		"available_commands": ["function", "for", "place_building"],
	},
	{
		"id": 4,
		"type": "do_it",
		"title": "Add build_roads",
		"mayor_dialogue": "Create function build_roads(row): that places a full row of roads at the given row. Call build_roads(2)!",
		"instruction": "Create:\nfunction build_roads(row):\n    place_building(\"road\", 0, row)\n    place_building(\"road\", 1, row)",
		"show_grid_diagram": false,
		"starter_code": "function build_residential():\n    place_building(\"house\", 0, 0)\n    place_building(\"house\", 1, 0)\n\nfunction build_commercial():\n    place_building(\"shop\", 0, 1)\n    place_building(\"shop\", 1, 1)\n\nbuild_residential()\nbuild_commercial()",
		"hint": "Add build_roads with a row parameter.",
		"success_condition": "count",
		"required_buildings": [],
		"required_count": 4,
		"required_types": 0,
		"available_commands": ["function", "for", "place_building"],
	},
	{
		"id": 5,
		"type": "do_it",
		"title": "Compose the District",
		"mayor_dialogue": "Now build_district() should only contain three lines: build_residential(), build_commercial(), build_roads(2). Each piece is named, readable, replaceable!",
		"instruction": "Create:\nfunction build_district():\n    build_residential()\n    build_commercial()\n    build_roads(2)\n\nCall build_district()!",
		"show_grid_diagram": false,
		"starter_code": "function build_residential():\n    place_building(\"house\", 0, 0)\n    place_building(\"house\", 1, 0)\n\nfunction build_commercial():\n    place_building(\"shop\", 0, 1)\n    place_building(\"shop\", 1, 1)\n\nfunction build_roads(row):\n    place_building(\"road\", 0, row)\n    place_building(\"road\", 1, row)",
		"hint": "Create build_district that calls the other functions.",
		"success_condition": "count",
		"required_buildings": [],
		"required_count": 6,
		"required_types": 0,
		"available_commands": ["function", "for", "place_building"],
	},
	{
		"id": 6,
		"type": "challenge",
		"title": "Add build_parks",
		"mayor_dialogue": "Add function build_parks(count): that places 'count' parks in a diagonal pattern!",
		"instruction": "Create:\nfunction build_parks(count):\n    for i in range(count):\n        place_building(\"park\", i, i)\n\nCall build_parks(2) from build_district!",
		"show_grid_diagram": false,
		"starter_code": "function build_residential():\n    place_building(\"house\", 0, 0)\n\nfunction build_commercial():\n    place_building(\"shop\", 0, 1)\n\nfunction build_district():\n    build_residential()\n    build_commercial()",
		"hint": "Use a loop with i in range(count) and place at (i, i).",
		"success_condition": "count",
		"required_buildings": [],
		"required_count": 3,
		"required_types": 0,
		"available_commands": ["function", "for", "place_building"],
	},
	{
		"id": 7,
		"type": "challenge",
		"title": "Add Happiness Check",
		"mayor_dialogue": "Add function run_happiness_check(): that prints a message. Call it last in build_district!",
		"instruction": "Create:\nfunction run_happiness_check():\n    print(\"District happiness check complete!\")\n\nCall it at the end of build_district().",
		"show_grid_diagram": false,
		"starter_code": "function build_residential():\n    place_building(\"house\", 0, 0)\n\nfunction build_district():\n    build_residential()",
		"hint": "Add print inside run_happiness_check.",
		"success_condition": "code_runs",
		"required_buildings": [],
		"required_count": 1,
		"required_types": 0,
		"available_commands": ["function", "for", "place_building", "print"],
	},
	{
		"id": 8,
		"type": "do_it",
		"title": "Full Architecture",
		"mayor_dialogue": "Complete the architecture: residential, commercial, roads, parks, happiness check — all composed together!",
		"instruction": "Build the complete district with 4 functions that call each other.",
		"show_grid_diagram": false,
		"starter_code": "function build_residential():\n    for i in range(3):\n        place_building(\"house\", i, 0)\n\nfunction build_commercial():\n    for i in range(3):\n        place_building(\"shop\", i, 1)",
		"hint": "Compose all 4 functions in build_district.",
		"success_condition": "count",
		"required_buildings": [],
		"required_count": 10,
		"required_types": 0,
		"available_commands": ["function", "for", "place_building", "print"],
	},
	{
		"id": 9,
		"type": "guided",
		"title": "Why Decomposition?",
		"mayor_dialogue": "Ask: if the roads were wrong, which function would you fix? They should immediately say build_roads. That is the value of decomposition!",
		"instruction": "The final build_district() reads like English:\nbuild_residential()\nbuild_commercial()\nbuild_roads()\n\nThat's the power of decomposition!",
		"show_grid_diagram": false,
		"starter_code": "function build_residential():\n    place_building(\"house\", 0, 0)\n\nfunction build_commercial():\n    place_building(\"shop\", 0, 1)\n\nfunction build_roads(row):\n    place_building(\"road\", 0, row)\n\nfunction build_district():\n    build_residential()\n    build_commercial()\n    build_roads(2)\n\nbuild_district()",
		"hint": "Read build_district() aloud — it sounds like English!",
		"success_condition": "count",
		"required_buildings": [],
		"required_count": 4,
		"required_types": 0,
		"available_commands": ["function", "for", "place_building"],
	},
	{
		"id": 10,
		"type": "mastery",
		"title": "Civic Center Architect",
		"mayor_dialogue": "You've mastered function composition! Build a complete civic center where every function has one job and calls the others.",
		"instruction": "Create 5 functions: build_plazas(count), build_pathways(), run_inspection(), plan_civic_center(), main(). Plan_civic_center orchestrates the others. Main calls plan_civic_center.",
		"show_grid_diagram": false,
		"starter_code": "function main():\n    print(\"Building civic center...\")",
		"hint": "Each function should do ONE thing well.",
		"success_condition": "count",
		"required_buildings": [],
		"required_count": 5,
		"required_types": 0,
		"available_commands": ["function", "for", "place_building", "print"],
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

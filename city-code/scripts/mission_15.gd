class_name Mission15
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

var mission_title := "Mission 15: The Autonomous City"
var mission_description := "Island 2 Capstone — Integrate all concepts!"
var starter_code := ""

var steps: Array = [
	{
		"id": 1,
		"type": "explain",
		"title": "The Master Builder",
		"mayor_dialogue": "Mayor — you have learned every tool the city needs. Variables. Loops. Functions. Dictionaries. Arrays. State machines. Conditions. Feedback. Now I am stepping back. This city is yours. A master builder does not follow instructions. They make decisions.",
		"instruction": "This is your capstone! Build a city using:\n1. Dictionaries for building records\n2. Arrays to store buildings\n3. Functions that call other functions\n4. While loops for time simulation\n5. State machines for NPCs\n6. Data-driven decisions",
		"show_grid_diagram": false,
		"starter_code": "",
		"hint": "",
		"success_condition": "explain",
		"required_buildings": [],
		"required_count": 0,
		"required_types": 0,
		"available_commands": ["var", "function", "if", "elif", "match", "for", "while", "place_building", "print", "return"],
	},
	{
		"id": 2,
		"type": "do_it",
		"title": "Plan Your City",
		"mayor_dialogue": "Before writing code: decide your city's name, district layout, and the functions you'll write. Planning is part of coding!",
		"instruction": "Write your city name and plan as comments. What buildings? What systems?",
		"show_grid_diagram": false,
		"starter_code": "# My City Plan\n# City name: ???\n# Districts: ???\n# Functions needed: ???",
		"hint": "Start with comments to plan your city.",
		"success_condition": "code_runs",
		"required_buildings": [],
		"required_count": 0,
		"required_types": 0,
		"available_commands": ["var", "function", "if", "elif", "match", "for", "while", "place_building", "print", "return"],
	},
	{
		"id": 3,
		"type": "do_it",
		"title": "Build the District",
		"mayor_dialogue": "Create your district array with at least 6 building records. Each must have type, x, y, and one more property!",
		"instruction": "Create var district with 6+ buildings. Each has type, x, y, and at least one more property (rating, happy, priority).",
		"show_grid_diagram": false,
		"starter_code": "var district = [\n    {\"type\": \"house\", \"x\": 0, \"y\": 0, \"rating\": 5}\n]",
		"hint": "Add more buildings with different properties.",
		"success_condition": "code_runs",
		"required_buildings": [],
		"required_count": 0,
		"required_types": 0,
		"available_commands": ["var", "function", "if", "elif", "match", "for", "while", "place_building", "print", "return"],
	},
	{
		"id": 4,
		"type": "do_it",
		"title": "Build the Systems",
		"mayor_dialogue": "Implement your 3+ functions. One must call another. Document each with a comment!",
		"instruction": "Create 3 functions. One calls another. Add comments explaining each function's purpose.",
		"show_grid_diagram": false,
		"starter_code": "# Builds the district from data\nfunction build_district():\n    print(\"Building district...\")\n\n# Calls build_district\nfunction run_city():\n    build_district()",
		"hint": "Create functions: build_district, simulate_day, print_report.",
		"success_condition": "code_runs",
		"required_buildings": [],
		"required_count": 0,
		"required_types": 0,
		"available_commands": ["var", "function", "if", "elif", "match", "for", "while", "place_building", "print", "return"],
	},
	{
		"id": 5,
		"type": "do_it",
		"title": "Simulate Time",
		"mayor_dialogue": "Add a while loop that runs for at least 5 simulated days. Each day: update your NPC state, apply changes!",
		"instruction": "Create a while loop that runs for 5 days. Inside: simulate a day (buildings or changes).",
		"show_grid_diagram": false,
		"starter_code": "var day = 0\n\nfunction simulate_day():\n    print(\"Day \" + str(day) + \"...\")\n\nwhile day < 5:\n    day += 1\n    simulate_day()",
		"hint": "Use: while day < 5: and increment day inside.",
		"success_condition": "code_runs",
		"required_buildings": [],
		"required_count": 0,
		"required_types": 0,
		"available_commands": ["var", "function", "if", "elif", "match", "for", "while", "place_building", "print", "return"],
	},
	{
		"id": 6,
		"type": "do_it",
		"title": "Add an NPC",
		"mayor_dialogue": "Create at least one NPC with a state machine. The NPC's state changes based on city conditions!",
		"instruction": "Add an NPC dictionary with state and happiness. Update state each day using if/elif or match.",
		"show_grid_diagram": false,
		"starter_code": "var npc = {\"state\": \"idle\", \"happiness\": 5}\n\nfunction update_npc():\n    if npc[\"happiness\"] > 7:\n        npc[\"state\"] = \"celebrating\"\n    elif npc[\"happiness\"] > 3:\n        npc[\"state\"] = \"working\"\n    else:\n        npc[\"state\"] = \"idle\"\n\nupdate_npc()\nprint(npc[\"state\"])",
		"hint": "NPC state should change based on happiness.",
		"success_condition": "code_runs",
		"required_buildings": [],
		"required_count": 0,
		"required_types": 0,
		"available_commands": ["var", "function", "if", "elif", "match", "for", "while", "place_building", "print", "return"],
	},
	{
		"id": 7,
		"type": "challenge",
		"title": "The Happiness Score",
		"mayor_dialogue": "Add a scoring system. Buildings affect happiness, and happiness affects NPC state. The loop continues!",
		"instruction": "Add var city_score. Buildings modify score. Score affects NPC. Print score each day.",
		"show_grid_diagram": false,
		"starter_code": "var city_score = 0\nvar npc = {\"state\": \"idle\", \"happiness\": 5}\n\nfunction update_npc():\n    if city_score > 20:\n        npc[\"happiness\"] += 1\n    else:\n        npc[\"happiness\"] -= 1\n    if npc[\"happiness\"] > 7:\n        npc[\"state\"] = \"celebrating\"",
		"hint": "Connect score to NPC happiness.",
		"success_condition": "code_runs",
		"required_buildings": [],
		"required_count": 0,
		"required_types": 0,
		"available_commands": ["var", "function", "if", "elif", "match", "for", "while", "place_building", "print", "return"],
	},
	{
		"id": 8,
		"type": "challenge",
		"title": "Place Buildings",
		"mayor_dialogue": "Place buildings based on your systems! NPC state, score thresholds, or data values should drive placement!",
		"instruction": "Add place_building calls based on NPC state or score. State: celebrating=park, working=shop, idle=house.",
		"show_grid_diagram": false,
		"starter_code": "var city_score = 0\nvar npc = {\"state\": \"idle\", \"happiness\": 5}\nvar day = 0\n\nfunction update_npc():\n    if npc[\"happiness\"] > 7:\n        npc[\"state\"] = \"celebrating\"",
		"hint": "Use match npc[\"state\"]: for building decisions.",
		"success_condition": "count",
		"required_buildings": [],
		"required_count": 5,
		"required_types": 0,
		"available_commands": ["var", "function", "if", "elif", "match", "for", "while", "place_building", "print", "return"],
	},
	{
		"id": 9,
		"type": "do_it",
		"title": "The Final Report",
		"mayor_dialogue": "Print a final city report! City name, total buildings, final score, NPC status, and your own city rating!",
		"instruction": "Create print_report() that prints: city name, buildings placed, final score, NPC state, and a rating.",
		"show_grid_diagram": false,
		"starter_code": "var city_name = \"My City\"\nvar city_score = 0\n\nfunction print_report(buildings):\n    print(\"=== \" + city_name + \" ===\")\n    print(\"Buildings: \" + str(buildings))\n    print(\"Score: \" + str(city_score))",
		"hint": "Add rating based on score thresholds.",
		"success_condition": "code_runs",
		"required_buildings": [],
		"required_count": 0,
		"required_types": 0,
		"available_commands": ["var", "function", "if", "elif", "match", "for", "while", "place_building", "print", "return"],
	},
	{
		"id": 10,
		"type": "mastery",
		"title": "Your Autonomous City",
		"mayor_dialogue": "You are now a master builder. Run your city, see the report, and know: you built this. Not from instructions, but from understanding. Welcome to the craft.",
		"instruction": "Complete your autonomous city! Requirements:\n1. District array (6+ dicts)\n2. 3+ functions (one calls another)\n3. While loop for time\n4. NPC with state machine\n5. Scoring system\n6. Final report\n\nThis is YOUR city. Build it!",
		"show_grid_diagram": false,
		"starter_code": "# ISLAND 2 CAPSTONE\n# Your city must have ALL of the following:\n# 1. A district array of building records (dicts)\n# 2. At least 3 functions (one calls another)\n# 3. A while loop that models time passing\n# 4. At least one NPC with a state machine\n# 5. A happiness scoring system\n# 6. A final report printed to the console\n\nvar city_name = \"Your City Name\"\nprint(\"Initialising \" + city_name + \"...\")",
		"hint": "Combine all concepts: dicts, arrays, functions, while, state, score, report.",
		"success_condition": "count",
		"required_buildings": [],
		"required_count": 10,
		"required_types": 0,
		"available_commands": ["var", "function", "if", "elif", "match", "for", "while", "place_building", "print", "return"],
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

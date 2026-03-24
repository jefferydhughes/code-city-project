class_name Mission10
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

var mission_title := "Mission 10: The City Census"
var mission_description := "Combine arrays and dictionaries to model city data."
var starter_code := ""

var steps: Array = [
	{
		"id": 1,
		"type": "explain",
		"title": "The City's Memory",
		"mayor_dialogue": "Mayor, the city has grown. But if you can't read your own city — who lives where, what zones are thriving — you're not a mayor. You're just watching. Today we build the city's memory!",
		"instruction": "A district is a list of building records:\n\nvar district = [\n    {\"type\": \"house\", \"x\": 0, \"y\": 0},\n    {\"type\": \"shop\", \"x\": 1, \"y\": 0}\n]",
		"show_grid_diagram": false,
		"starter_code": "",
		"hint": "",
		"success_condition": "explain",
		"required_buildings": [],
		"required_count": 0,
		"required_types": 0,
		"available_commands": ["var", "for", "if", "place_building"],
	},
	{
		"id": 2,
		"type": "do_it",
		"title": "Run the District",
		"mayor_dialogue": "Run the starter code. Three buildings appear from the district array. Every position comes from its record!",
		"instruction": "Run the code. Three buildings appear based on their dictionary records.",
		"show_grid_diagram": false,
		"starter_code": "var district = [\n    {\"type\": \"house\", \"x\": 0, \"y\": 0},\n    {\"type\": \"shop\", \"x\": 1, \"y\": 0},\n    {\"type\": \"park\", \"x\": 2, \"y\": 0}\n]\nfor b in district:\n    place_building(b[\"type\"], b[\"x\"], b[\"y\"])",
		"hint": "Press Run to see buildings placed from the array.",
		"success_condition": "count",
		"required_buildings": [],
		"required_count": 3,
		"required_types": 0,
		"available_commands": ["var", "for", "if", "place_building"],
	},
	{
		"id": 3,
		"type": "do_it",
		"title": "Filter the Happy Ones",
		"mayor_dialogue": "Modify the loop: only place buildings where happy > 5. Low-happiness buildings don't get placed!",
		"instruction": "Add: if b[\"happy\"] > 5:\nbefore place_building.\nSome buildings will be skipped!",
		"show_grid_diagram": false,
		"starter_code": "var district = [\n    {\"type\": \"house\", \"x\": 0, \"y\": 0, \"happy\": 3},\n    {\"type\": \"shop\", \"x\": 1, \"y\": 0, \"happy\": 7},\n    {\"type\": \"park\", \"x\": 2, \"y\": 0, \"happy\": 9}\n]\nfor b in district:\n    place_building(b[\"type\"], b[\"x\"], b[\"y\"])",
		"hint": "Add: if b[\"happy\"] > 5: before place_building.",
		"success_condition": "count",
		"required_buildings": [],
		"required_count": 2,
		"required_types": 0,
		"available_commands": ["var", "for", "if", "place_building"],
	},
	{
		"id": 4,
		"type": "do_it",
		"title": "Report the Census",
		"mayor_dialogue": "Add a print statement that outputs each building's type and happiness score!",
		"instruction": "Add: print(b[\"type\"] + \": \" + str(b[\"happy\"]))\ninside the loop to report the census.",
		"show_grid_diagram": false,
		"starter_code": "var district = [\n    {\"type\": \"house\", \"x\": 0, \"y\": 0, \"happy\": 3},\n    {\"type\": \"shop\", \"x\": 1, \"y\": 0, \"happy\": 7},\n    {\"type\": \"park\", \"x\": 2, \"y\": 0, \"happy\": 9}\n]\nfor b in district:\n    if b[\"happy\"] > 5:\n        place_building(b[\"type\"], b[\"x\"], b[\"y\"])",
		"hint": "Add print inside the loop: print(b[\"type\"] + \": happy \" + str(b[\"happy\"]))",
		"success_condition": "code_runs",
		"required_buildings": [],
		"required_count": 2,
		"required_types": 0,
		"available_commands": ["var", "for", "if", "place_building", "print"],
	},
	{
		"id": 5,
		"type": "do_it",
		"title": "Add a Building",
		"mayor_dialogue": "Append a new record to district. The loop handles it automatically — that's the power of data!",
		"instruction": "Add to the district array:\n{\"type\": \"tree\", \"x\": 3, \"y\": 0, \"happy\": 6}",
		"show_grid_diagram": false,
		"starter_code": "var district = [\n    {\"type\": \"house\", \"x\": 0, \"y\": 0, \"happy\": 3},\n    {\"type\": \"shop\", \"x\": 1, \"y\": 0, \"happy\": 7},\n    {\"type\": \"park\", \"x\": 2, \"y\": 0, \"happy\": 9}\n]\nfor b in district:\n    if b[\"happy\"] > 5:\n        place_building(b[\"type\"], b[\"x\"], b[\"y\"])",
		"hint": "Add a 4th entry to the array with type: \"tree\".",
		"success_condition": "count",
		"required_buildings": [],
		"required_count": 3,
		"required_types": 0,
		"available_commands": ["var", "for", "if", "place_building", "print"],
	},
	{
		"id": 6,
		"type": "challenge",
		"title": "The Full Block",
		"mayor_dialogue": "Create a district of 8 buildings. Filter: happy > 4 goes to premium (y=1), others go to y=3.",
		"instruction": "Build 8 buildings. happy > 4 → row 1 (premium).\nhappy <= 4 → row 3 (economy).",
		"show_grid_diagram": false,
		"starter_code": "var district = [\n    {\"type\": \"house\", \"x\": 0, \"y\": 0, \"happy\": 3},\n    {\"type\": \"shop\", \"x\": 1, \"y\": 0, \"happy\": 7}\n]\nfor b in district:\n    place_building(b[\"type\"], b[\"x\"], b[\"y\"])",
		"hint": "Use if/else based on b[\"happy\"] > 4 to choose row.",
		"success_condition": "count",
		"required_buildings": [],
		"required_count": 8,
		"required_types": 0,
		"available_commands": ["var", "for", "if", "else", "place_building", "print"],
	},
	{
		"id": 7,
		"type": "guided",
		"title": "len() Function",
		"mayor_dialogue": "Use len(district) to get the number of buildings in the array!",
		"instruction": "Print: print(\"Total buildings: \" + str(len(district)))",
		"show_grid_diagram": false,
		"starter_code": "var district = [\n    {\"type\": \"house\", \"x\": 0, \"y\": 0, \"happy\": 5},\n    {\"type\": \"shop\", \"x\": 1, \"y\": 0, \"happy\": 6}\n]\nfor b in district:\n    place_building(b[\"type\"], b[\"x\"], b[\"y\"])",
		"hint": "len() returns the size of an array.",
		"success_condition": "code_runs",
		"required_buildings": [],
		"required_count": 2,
		"required_types": 0,
		"available_commands": ["var", "for", "if", "place_building", "print", "len"],
	},
	{
		"id": 8,
		"type": "do_it",
		"title": "Calculate Average",
		"mayor_dialogue": "Add all happy values, divide by count to get the average happiness!",
		"instruction": "Use a variable 'total' to sum happiness, then divide by len(district) for average.",
		"show_grid_diagram": false,
		"starter_code": "var district = [\n    {\"type\": \"house\", \"x\": 0, \"y\": 0, \"happy\": 5},\n    {\"type\": \"shop\", \"x\": 1, \"y\": 0, \"happy\": 7},\n    {\"type\": \"park\", \"x\": 2, \"y\": 0, \"happy\": 9}\n]\nvar total = 0\nfor b in district:\n    total = total + b[\"happy\"]",
		"hint": "Print: \"Average: \" + str(total / len(district))",
		"success_condition": "code_runs",
		"required_buildings": [],
		"required_count": 0,
		"required_types": 0,
		"available_commands": ["var", "for", "if", "place_building", "print", "len"],
	},
	{
		"id": 9,
		"type": "challenge",
		"title": "District Summary",
		"mayor_dialogue": "Build a complete census report with total buildings, average happiness, and zone placement!",
		"instruction": "Create 6 buildings. Print: total count, average happiness, and place happy ones at row 1, others at row 3.",
		"show_grid_diagram": false,
		"starter_code": "var district = [\n    {\"type\": \"house\", \"x\": 0, \"y\": 0, \"happy\": 4},\n    {\"type\": \"shop\", \"x\": 1, \"y\": 0, \"happy\": 8},\n    {\"type\": \"park\", \"x\": 2, \"y\": 0, \"happy\": 6},\n    {\"type\": \"tree\", \"x\": 3, \"y\": 0, \"happy\": 3},\n    {\"type\": \"house\", \"x\": 4, \"y\": 0, \"happy\": 7},\n    {\"type\": \"shop\", \"x\": 5, \"y\": 0, \"happy\": 5}\n]",
		"hint": "Loop, filter by happy > 5 for row 1, else row 3.",
		"success_condition": "count",
		"required_buildings": [],
		"required_count": 6,
		"required_types": 0,
		"available_commands": ["var", "for", "if", "else", "place_building", "print", "len"],
	},
	{
		"id": 10,
		"type": "mastery",
		"title": "City Data Analyst",
		"mayor_dialogue": "You've mastered data-driven building! Build a full census system that reads city data and makes placement decisions.",
		"instruction": "Create 8 buildings with 'type', 'x', 'y', 'happy'. Use len() and conditional logic to: place happy > 4 at row 1, print average happiness, print total count.",
		"show_grid_diagram": false,
		"starter_code": "var city_data = [\n    {\"type\": \"house\", \"x\": 0, \"y\": 0, \"happy\": 5},\n    {\"type\": \"shop\", \"x\": 1, \"y\": 0, \"happy\": 8}\n]",
		"hint": "Calculate total, use len(), filter by happiness.",
		"success_condition": "count",
		"required_buildings": [],
		"required_count": 8,
		"required_types": 0,
		"available_commands": ["var", "for", "if", "else", "place_building", "print", "len"],
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

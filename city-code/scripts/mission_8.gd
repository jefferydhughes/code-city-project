class_name Mission8
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

var mission_title := "Mission 8: The Dictionary District"
var mission_description := "Learn to use dictionaries (key-value data)."
var starter_code := ""

var steps: Array = [
	{
		"id": 1,
		"type": "explain",
		"title": "The City Database",
		"mayor_dialogue": "Mayor, our shops are running blind. They don't know their own prices, stock counts, or ratings. We need a smarter way to store information — not just one value, but whole records!",
		"instruction": "A dictionary stores multiple pieces of info about one thing, using KEY-VALUE pairs:\n\nvar shop = {\"name\": \"Bakery\", \"stock\": 10, \"rating\": 4}\n\nKeys are like labels, values are the data.",
		"show_grid_diagram": false,
		"starter_code": "",
		"hint": "",
		"success_condition": "explain",
		"required_buildings": [],
		"required_count": 0,
		"required_types": 0,
		"available_commands": ["var", "print", "place_building"],
	},
	{
		"id": 2,
		"type": "do_it",
		"title": "One Building, Many Facts",
		"mayor_dialogue": "Run the starter code. The bakery appears, and its name is printed to the console. A dictionary stores all of that in one variable!",
		"instruction": "Run the code. Watch the bakery appear and check the console output.",
		"show_grid_diagram": false,
		"starter_code": "var shop = {\"name\": \"Bakery\", \"stock\": 10, \"rating\": 4}\nprint(shop[\"name\"])\nplace_building(\"shop\", 2, 2)",
		"hint": "Press Run to execute the code.",
		"success_condition": "code_runs",
		"required_buildings": [],
		"required_count": 0,
		"required_types": 0,
		"available_commands": ["var", "print", "place_building", "if"],
	},
	{
		"id": 3,
		"type": "do_it",
		"title": "Read the Data",
		"mayor_dialogue": "Change print(shop[\"name\"]) to print(shop[\"rating\"]). The console will show 4 — the bakery's rating!",
		"instruction": "Change print(shop[\"name\"]) to print(shop[\"rating\"]).\nRun it — the console shows 4!",
		"show_grid_diagram": false,
		"starter_code": "var shop = {\"name\": \"Bakery\", \"stock\": 10, \"rating\": 4}\nprint(shop[\"name\"])\nplace_building(\"shop\", 2, 2)",
		"hint": "Change shop[\"name\"] to shop[\"rating\"]",
		"success_condition": "code_runs",
		"required_buildings": [],
		"required_count": 0,
		"required_types": 0,
		"available_commands": ["var", "print", "place_building", "if"],
	},
	{
		"id": 4,
		"type": "do_it",
		"title": "Build Based on Rating",
		"mayor_dialogue": "Add an if block: if shop[\"rating\"] > 3, place a second shop at (3, 2). A highly-rated bakery earns an expansion!",
		"instruction": "Add: if shop[\"rating\"] > 3:\n    place_building(\"shop\", 3, 2)\n\nA shop with rating > 3 should get a second building!",
		"show_grid_diagram": false,
		"starter_code": "var shop = {\"name\": \"Bakery\", \"stock\": 10, \"rating\": 4}\nplace_building(\"shop\", 2, 2)",
		"hint": "Add:\nif shop[\"rating\"] > 3:\n    place_building(\"shop\", 3, 2)",
		"success_condition": "specific_buildings",
		"required_buildings": ["shop:3:2"],
		"required_count": 2,
		"required_types": 1,
		"available_commands": ["var", "print", "place_building", "if"],
	},
	{
		"id": 5,
		"type": "do_it",
		"title": "Update the Record",
		"mayor_dialogue": "Add shop[\"stock\"] = 0 before the if block, then check if stock > 0 before placing. Out of stock? No expansion!",
		"instruction": "Add: shop[\"stock\"] = 0\nbefore the if block.\nNow change the if to check stock instead of rating.",
		"show_grid_diagram": false,
		"starter_code": "var shop = {\"name\": \"Bakery\", \"stock\": 10, \"rating\": 4}\nplace_building(\"shop\", 2, 2)\nif shop[\"rating\"] > 3:\n    place_building(\"shop\", 3, 2)",
		"hint": "Add shop[\"stock\"] = 0, then change rating check to stock check.",
		"success_condition": "count",
		"required_buildings": [],
		"required_count": 1,
		"required_types": 0,
		"available_commands": ["var", "print", "place_building", "if"],
	},
	{
		"id": 6,
		"type": "challenge",
		"title": "A Full City Block",
		"mayor_dialogue": "Create three shop dictionaries with different ratings. Use a loop to place each one — only shops with rating >= 4 get placed in the premium zone (row 1), others go to row 3.",
		"instruction": "Create three shops with different ratings. Loop through them:\n- Rating >= 4 goes to row 1 (premium zone)\n- Rating < 4 goes to row 3 (economy zone)",
		"show_grid_diagram": false,
		"starter_code": "var shops = [\n    {\"name\": \"Bakery\", \"rating\": 5},\n    {\"name\": \"Hardware\", \"rating\": 3},\n    {\"name\": \"Florist\", \"rating\": 4}\n]\nfor i in range(3):\n    place_building(\"shop\", i, 2)",
		"hint": "Use: if shops[i][\"rating\"] >= 4:\n    place_building(\"shop\", i, 1)\nelse:\n    place_building(\"shop\", i, 3)",
		"success_condition": "specific_buildings",
		"required_buildings": ["shop:0:1", "shop:2:1", "shop:1:3"],
		"required_count": 3,
		"required_types": 1,
		"available_commands": ["var", "print", "place_building", "if", "for"],
	},
	{
		"id": 7,
		"type": "guided",
		"title": "Dict in Dict",
		"mayor_dialogue": "Sometimes you need to look up values within dictionaries. The key is always a string in quotes!",
		"instruction": "Access dict values with dict[\"key\"] — the key must be a STRING (in quotes).",
		"show_grid_diagram": false,
		"starter_code": "var data = {\"count\": 5, \"active\": true}\nprint(data[\"count\"])",
		"hint": "Keys are always strings: data[\"count\"]",
		"success_condition": "code_runs",
		"required_buildings": [],
		"required_count": 0,
		"required_types": 0,
		"available_commands": ["var", "print", "place_building", "if"],
	},
	{
		"id": 8,
		"type": "do_it",
		"title": "Update Dictionary Values",
		"mayor_dialogue": "You can change dictionary values! Just assign a new value: dict[\"key\"] = newValue",
		"instruction": "Add: shop[\"rating\"] = 5\nbefore placing. The rating increases!",
		"show_grid_diagram": false,
		"starter_code": "var shop = {\"name\": \"Bakery\", \"rating\": 3}\nplace_building(\"shop\", 2, 2)\nif shop[\"rating\"] > 3:\n    place_building(\"shop\", 3, 2)",
		"hint": "Add shop[\"rating\"] = 5 before the if statement.",
		"success_condition": "specific_buildings",
		"required_buildings": ["shop:2:2", "shop:3:2"],
		"required_count": 2,
		"required_types": 1,
		"available_commands": ["var", "print", "place_building", "if"],
	},
	{
		"id": 9,
		"type": "challenge",
		"title": "The City Records",
		"mayor_dialogue": "Build a mini database of 4 buildings with different properties. Use conditionals to place each in the right zone based on their data!",
		"instruction": "Create 4 buildings with different 'type' and 'priority' values. High priority (>3) goes to row 1, others to row 3.",
		"show_grid_diagram": false,
		"starter_code": "var buildings = [\n    {\"type\": \"shop\", \"priority\": 5},\n    {\"type\": \"house\", \"priority\": 2},\n    {\"type\": \"park\", \"priority\": 4},\n    {\"type\": \"tree\", \"priority\": 1}\n]\nfor i in range(4):\n    place_building(buildings[i][\"type\"], i, 2)",
		"hint": "Check buildings[i][\"priority\"] in your loop to decide placement.",
		"success_condition": "specific_buildings",
		"required_buildings": ["shop:0:1", "house:1:3", "park:2:1", "tree:3:3"],
		"required_count": 4,
		"required_types": 4,
		"available_commands": ["var", "print", "place_building", "if", "for"],
	},
	{
		"id": 10,
		"type": "mastery",
		"title": "District Database",
		"mayor_dialogue": "You've mastered dictionaries! Build a complete district system where building data drives every placement decision.",
		"instruction": "Build a 5-building district where each building has 'type', 'x', 'y', and 'rating'. Use dict data to decide: rating >= 4 = premium (row 1), else = economy (row 3). Print the rating of each building placed.",
		"show_grid_diagram": false,
		"starter_code": "var district = [\n    {\"type\": \"shop\", \"rating\": 5},\n    {\"type\": \"house\", \"rating\": 3},\n    {\"type\": \"park\", \"rating\": 4},\n    {\"type\": \"shop\", \"rating\": 2},\n    {\"type\": \"tree\", \"rating\": 5}\n]\nfor i in range(5):\n    place_building(district[i][\"type\"], i, 2)",
		"hint": "Check rating >= 4 for premium zone, print each rating.",
		"success_condition": "count",
		"required_buildings": [],
		"required_count": 5,
		"required_types": 0,
		"available_commands": ["var", "print", "place_building", "if", "for"],
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
	var children = get_tree().get_nodes_in_group("placed_building")
	for child in children:
		placed_buildings.append(child.name)


func _check_success() -> bool:
	var step = steps[current_step_index]
	var success_type = step.success_condition
	
	match success_type:
		"explain":
			return true
		"code_runs":
			return true
		"specific_buildings":
			return _check_specific_buildings(step)
		"count":
			return _check_count(step)
		"type_count":
			return _check_type_count(step)
	
	return false


func _check_specific_buildings(step: Dictionary) -> bool:
	var required = step.required_buildings as Array
	if required.is_empty():
		return false
	
	var children = get_tree().get_nodes_in_group("placed_building")
	if children.size() < required.size():
		return false
	
	var found_count = 0
	for req in required:
		var parts = req.split(":")
		if parts.size() != 3:
			continue
		var type_name = parts[0]
		var x = parts[1].to_int()
		var z = parts[2].to_int()
		
		for child in children:
			if child.get("building_type") == type_name:
				var pos = child.global_position
				if abs(pos.x - x) < 1.5 and abs(pos.z - z) < 1.5:
					found_count += 1
					break
	
	return found_count >= required.size()


func _check_count(step: Dictionary) -> bool:
	var required = step.get("required_count", 0) as int
	if required == 0:
		return false
	
	var children = get_tree().get_nodes_in_group("placed_building")
	return children.size() >= required


func _check_type_count(step: Dictionary) -> bool:
	var required = step.get("required_types", 0) as int
	if required == 0:
		return false
	
	var children = get_tree().get_nodes_in_group("placed_building")
	var types = {}
	for child in children:
		var t = child.get("building_type", "")
		if t:
			types[t] = true
	return types.size() >= required


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
